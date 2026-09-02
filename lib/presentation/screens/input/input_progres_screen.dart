import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/geotagging_service.dart';
import '../../../data/models/paket_pekerjaan.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/watermark_preview.dart';
import '../../providers/paket_provider.dart';

class InputProgresScreen extends StatefulWidget {
  final PaketPekerjaan package;

  const InputProgresScreen({super.key, required this.package});

  @override
  State<InputProgresScreen> createState() => _InputProgresScreenState();
}

class _InputProgresScreenState extends State<InputProgresScreen> {
  final _formKey = GlobalKey<FormState>();
  late double _progresFisik;
  final TextEditingController _progresTextController = TextEditingController();
  final TextEditingController _keuanganTextController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _info1Controller = TextEditingController();
  final TextEditingController _info2Controller = TextEditingController();

  String? _foto1Path;
  String? _foto2Path;
  bool _foto1Watermarked = false; // true = watermark sudah ter-burn ke file
  bool _foto2Watermarked = false;

  // GPS state — nullable, diisi saat lokasi berhasil didapat
  double? _latitude;
  double? _longitude;
  double? _gpsAccuracy;
  bool _hasLocation = false;
  bool _isGettingLocation = false;

  DateTime _currentTimestamp = DateTime.now();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _progresFisik = widget.package.progresFisikSaatIni;
    _progresTextController.text = _progresFisik.toStringAsFixed(1);
    double initialKeuangan = widget.package.realisasiKeuangan > 0
        ? widget.package.realisasiKeuangan
        : widget.package.nilaiKontrak * (_progresFisik / 100);
    _keuanganTextController.text = initialKeuangan.toStringAsFixed(0);
    _initDeviceLocation();
  }

  @override
  void dispose() {
    _progresTextController.dispose();
    _keuanganTextController.dispose();
    _catatanController.dispose();
    _info1Controller.dispose();
    _info2Controller.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _initDeviceLocation() async {
    setState(() => _isGettingLocation = true);
    await _fetchLocation();
    if (mounted) setState(() => _isGettingLocation = false);
  }

  /// Coba ambil lokasi GPS. Jika service mati atau izin ditolak, biarkan
  /// _hasLocation = false tanpa menampilkan error (opsional).
  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      if (permission == LocationPermission.denied) return;

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _gpsAccuracy = position.accuracy;
          _hasLocation = true;
        });
      }
    } catch (_) {
      // Lokasi opsional — abaikan error
    }
  }

  // ── Image Picking + Geotagging ───────────────────────────────────────────────

  Future<void> _pickImage(int photoIndex, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      // Update timestamp saat foto diambil
      final DateTime captureTime = DateTime.now();
      setState(() => _currentTimestamp = captureTime);

      // Refresh lokasi terbaru jika belum punya (prioritas kamera)
      if (!_hasLocation) {
        await _fetchLocation();
      }

      // ── BURN WATERMARK ke file foto (kamera & galeri) ──────────────────────
      // Ini adalah file BARU yang akan dikirim ke server.
      // File asli dari kamera/galeri TIDAK dimodifikasi.
      String finalPath;
      bool burnSuccess = false;

      try {
        final GeotagResult result = await GeotaggingService.burnWatermark(
          imagePath: pickedFile.path,
          packageName: widget.package.packageName,
          kegiatanName: widget.package.kegiatan,
          timestamp: captureTime,
          latitude: _hasLocation ? _latitude : null,
          longitude: _hasLocation ? _longitude : null,
          accuracy: _gpsAccuracy,
        );
        finalPath = result.path;
        burnSuccess = true;
        debugPrint('✅ Watermark ter-burn ke: $finalPath');
      } catch (burnError) {
        // Jika burn gagal, gunakan foto asli tapi beri peringatan
        debugPrint('⚠️ Burn watermark gagal: $burnError');
        finalPath = pickedFile.path;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peringatan: Watermark gagal diterapkan ke foto. ($burnError)'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          if (photoIndex == 1) {
            _foto1Path = finalPath;
            _foto1Watermarked = burnSuccess;
          } else {
            _foto2Path = finalPath;
            _foto2Watermarked = burnSuccess;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  void _submitProgressToApi() async {
    if (_foto1Path == null || _foto1Path!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto 1 wajib diunggah sebagai dokumen utama.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final paketProvider = Provider.of<PaketProvider>(context, listen: false);

      final double majukeuangan = double.tryParse(
            _keuanganTextController.text
                .replaceAll('.', '')
                .replaceAll(',', '.'),
          ) ??
          0.0;

      try {
        final success = await paketProvider.postKendaliProgress(
          proyekId: widget.package.id,
          majufreal: _progresFisik,
          majukeuangan: majukeuangan,
          keterangan: _catatanController.text.trim(),
          foto1Path: _foto1Path!,
          foto2Path: _foto2Path,
          info1: _info1Controller.text.trim().isNotEmpty
              ? _info1Controller.text.trim()
              : null,
          info2: _info2Controller.text.trim().isNotEmpty
              ? _info2Controller.text.trim()
              : null,
        );

        if (mounted) {
          if (success) {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 8),
                    Text('Laporan Terkirim', style: GoogleFonts.outfit()),
                  ],
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Lembar kendali progres fisik ${_progresFisik.toStringAsFixed(1)}% berhasil diterima server dan menunggu verifikasi.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          } else {
            _showErrorDialog(paketProvider.errorMessage ??
                'Gagal mengirim data progres ke server.');
          }
        }
      } catch (e) {
        if (mounted) _showErrorDialog('Terjadi kesalahan: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Gagal Mengirim', style: GoogleFonts.outfit()),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tutup'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final paketProvider = Provider.of<PaketProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Input Progres Kendali',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Tombol refresh lokasi
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isGettingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CupertinoActivityIndicator(radius: 9),
                  )
                : IconButton(
                    icon: Icon(
                      _hasLocation
                          ? CupertinoIcons.location_fill
                          : CupertinoIcons.location_slash_fill,
                      size: 18,
                      color:
                          _hasLocation ? AppColors.primary : AppColors.textSecondary,
                    ),
                    tooltip: _hasLocation ? 'Lokasi aktif' : 'Refresh lokasi',
                    onPressed: () async {
                      setState(() => _isGettingLocation = true);
                      await _fetchLocation();
                      if (mounted) setState(() => _isGettingLocation = false);
                    },
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Package Info Header Card ─────────────────────────────────
                IosCard(
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.primary.withAlpha(51)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.package.packageId,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID Paket: ${widget.package.id}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.package.packageName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.package.kegiatan.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.package.kegiatan,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location_solid,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.package.lokasi ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── GPS Status Bar ───────────────────────────────────────────
                _buildGpsStatusBar(),
                const SizedBox(height: 8),

                // ── Realisasi Fisik Section ──────────────────────────────────
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Realisasi Fisik (%)',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_progresFisik.toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: const Color(0xFFE5E5EA),
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withAlpha(51),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                            elevation: 4,
                          ),
                        ),
                        child: Slider(
                          value: _progresFisik,
                          min: 0.0,
                          max: 100.0,
                          divisions: 200,
                          onChanged: (val) {
                            setState(() {
                              _progresFisik = val;
                              _progresTextController.text =
                                  val.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      IosTextField(
                        label: 'Input Persentase Fisik (0 - 100)',
                        hint: 'Contoh: 48.5',
                        controller: _progresTextController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null &&
                              parsed >= 0 &&
                              parsed <= 100) {
                            setState(() => _progresFisik = parsed);
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Realisasi fisik wajib diisi';
                          }
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal < 0 || numVal > 100) {
                            return 'Harus angka persentase antara 0 - 100';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // ── Nilai Tagihan Keuangan Section ───────────────────────────
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nilai Tagihan Keuangan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nilai kumulatif tagihan keuangan (Rupiah)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IosTextField(
                        label: 'Nominal Tagihan Keuangan (Rp)',
                        hint: 'Contoh: 90000000',
                        controller: _keuanganTextController,
                        keyboardType: TextInputType.number,
                        prefixIcon: CupertinoIcons.money_dollar_circle_fill,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Nilai tagihan keuangan wajib diisi';
                          }
                          final cleanVal = double.tryParse(
                              val.replaceAll('.', '').replaceAll(',', '.'));
                          if (cleanVal == null || cleanVal < 0) {
                            return 'Masukkan nominal yang valid';
                          }
                          return null;
                        },
                      ),
                      if (_keuanganTextController.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Format: ${CurrencyFormatter.format(double.tryParse(_keuanganTextController.text) ?? 0.0)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // ── Catatan Section ──────────────────────────────────────────
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Field / Kendala',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      IosTextField(
                        label: '',
                        hint: 'Catatan kondisi lapangan, kendala teknis/cuaca...',
                        controller: _catatanController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // ── Foto 1 (Wajib) Section ───────────────────────────────────
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Foto 1 Dokumentasi',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '*Required',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Watermark Preview Foto 1
                      WatermarkPreview(
                        imagePath: _foto1Path,
                        latitude: _latitude,
                        longitude: _longitude,
                        accuracy: _gpsAccuracy,
                        hasLocation: _hasLocation,
                        timestamp: _currentTimestamp,
                        packageName: widget.package.packageName,
                        kegiatanName: widget.package.kegiatan,
                        onPickCamera: () => _pickImage(1, ImageSource.camera),
                        onPickGallery: () => _pickImage(1, ImageSource.gallery),
                        onRemove: _foto1Path != null
                            ? () => setState(() => _foto1Path = null)
                            : null,
                      ),
                      const SizedBox(height: 6),

                      // Status watermark burn
                      if (_foto1Path != null)
                        _buildWatermarkBadge(_foto1Watermarked),
                      const SizedBox(height: 10),

                      // Info 1 field
                      IosTextField(
                        label: 'Keterangan Foto 1 (info1)',
                        hint:
                            'Contoh: Kondisi jembatan tampak depan, progres 70%...',
                        controller: _info1Controller,
                        prefixIcon: CupertinoIcons.info_circle,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // ── Foto 2 (Opsional) Section ────────────────────────────────
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Foto 2 Dokumentasi',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Watermark Preview Foto 2 (sama seperti foto 1)
                      WatermarkPreview(
                        imagePath: _foto2Path,
                        latitude: _latitude,
                        longitude: _longitude,
                        accuracy: _gpsAccuracy,
                        hasLocation: _hasLocation,
                        timestamp: _currentTimestamp,
                        packageName: widget.package.packageName,
                        kegiatanName: widget.package.kegiatan,
                        onPickCamera: () => _pickImage(2, ImageSource.camera),
                        onPickGallery: () => _pickImage(2, ImageSource.gallery),
                        onRemove: _foto2Path != null
                            ? () => setState(() => _foto2Path = null)
                            : null,
                      ),
                      const SizedBox(height: 6),

                      // Status watermark burn foto 2
                      if (_foto2Path != null)
                        _buildWatermarkBadge(_foto2Watermarked),
                      const SizedBox(height: 10),

                      // Info 2 field (hanya aktif jika foto 2 ada)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: IosTextField(
                          label: 'Keterangan Foto 2 (info2)',
                          hint:
                              'Contoh: Detail penulangan beton, tampak samping...',
                          controller: _info2Controller,
                          prefixIcon: CupertinoIcons.info_circle,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Submit Button ────────────────────────────────────────────
                IosButton(
                  label: 'Kirim Lembar Kendali',
                  icon: CupertinoIcons.cloud_upload_fill,
                  isLoading: paketProvider.isLoading,
                  onPressed: _submitProgressToApi,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── GPS Status Bar Widget ────────────────────────────────────────────────────

  Widget _buildGpsStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _hasLocation
            ? AppColors.success.withAlpha(15)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _hasLocation
              ? AppColors.success.withAlpha(60)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isGettingLocation
                ? CupertinoIcons.location
                : (_hasLocation
                    ? CupertinoIcons.location_fill
                    : CupertinoIcons.location_slash_fill),
            size: 14,
            color: _isGettingLocation
                ? AppColors.primary
                : (_hasLocation ? AppColors.success : AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _isGettingLocation
                ? Text(
                    'Mengambil koordinat GPS...',
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: AppColors.primary),
                  )
                : _hasLocation
                    ? Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}  ±${_gpsAccuracy?.toStringAsFixed(1) ?? '?'}m',
                        style: GoogleFonts.robotoMono(
                            fontSize: 11, color: AppColors.success),
                      )
                    : Text(
                        'Lokasi tidak tersedia — watermark tanpa koordinat GPS',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
          ),
          if (_isGettingLocation)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: CupertinoActivityIndicator(radius: 6),
            ),
        ],
      ),
    );
  }

  // ── Watermark Status Badge ───────────────────────────────────────────────────

  Widget _buildWatermarkBadge(bool isWatermarked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWatermarked
            ? AppColors.success.withAlpha(20)
            : Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWatermarked
              ? AppColors.success.withAlpha(80)
              : Colors.orange.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWatermarked
                ? CupertinoIcons.checkmark_seal_fill
                : CupertinoIcons.exclamationmark_triangle,
            size: 13,
            color: isWatermarked ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 5),
          Text(
            isWatermarked
                ? 'Watermark ter-burn ke file foto ✓'
                : 'Watermark belum diterapkan ke file',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isWatermarked ? AppColors.success : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
