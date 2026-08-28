import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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

  String? _foto1Path;
  String? _foto2Path;
  double _latitude = -4.0152;
  double _longitude = 135.9521;
  double _gpsAccuracy = 4.2;
  DateTime _currentTimestamp = DateTime.now();
  bool _isGettingLocation = false;

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
    super.dispose();
  }

  Future<void> _initDeviceLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );

          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _gpsAccuracy = position.accuracy;
          });
        }
      }
    } catch (_) {
      // Keep existing coordinates
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(int photoIndex, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          if (photoIndex == 1) {
            _foto1Path = pickedFile.path;
          } else {
            _foto2Path = pickedFile.path;
          }
          _currentTimestamp = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

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

      final double majukeuangan = double.tryParse(_keuanganTextController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

      try {
        final success = await paketProvider.postKendaliProgress(
          proyekId: widget.package.id,
          majufreal: _progresFisik,
          majukeuangan: majukeuangan,
          keterangan: _catatanController.text.trim(),
          foto1Path: _foto1Path!,
          foto2Path: _foto2Path,
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
            _showErrorDialog(paketProvider.errorMessage ?? 'Gagal mengirim data progres ke server.');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Terjadi kesalahan: $e');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Gagal Mengirim', style: GoogleFonts.outfit()),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: GoogleFonts.inter(fontSize: 13),
          ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Info Card Header
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

                // Realisasi Fisik (majufreal) Section
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
                              _progresTextController.text = val.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      IosTextField(
                        label: 'Input Persentase Fisik (0 - 100)',
                        hint: 'Contoh: 48.5',
                        controller: _progresTextController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0 && parsed <= 100) {
                            setState(() {
                              _progresFisik = parsed;
                            });
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Realisasi fisik wajib diisi';
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

                // Nilai Tagihan Keuangan saat ini (majukeuangan) Section
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
                          if (val == null || val.isEmpty) return 'Nilai tagihan keuangan wajib diisi';
                          final cleanVal = double.tryParse(val.replaceAll('.', '').replaceAll(',', '.'));
                          if (cleanVal == null || cleanVal < 0) return 'Masukkan nominal yang valid';
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

                // Field Notes Section (keterangan)
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Field / Kendala (keterangan)',
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

                // Foto 1 (Wajib) Section
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      WatermarkPreview(
                        imagePath: _foto1Path,
                        latitude: _latitude,
                        longitude: _longitude,
                        accuracy: _gpsAccuracy,
                        timestamp: _currentTimestamp,
                        packageName: widget.package.packageName,
                        onPickCamera: () => _pickImage(1, ImageSource.camera),
                        onPickGallery: () => _pickImage(1, ImageSource.gallery),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location_circle, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)} (±${_gpsAccuracy.toStringAsFixed(1)}m)',
                            style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textSecondary),
                          ),
                          if (_isGettingLocation) ...[
                            const SizedBox(width: 8),
                            const CupertinoActivityIndicator(radius: 6),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Foto 2 (Opsional) Section
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      _foto2Path != null && _foto2Path!.isNotEmpty
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_foto2Path!),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(CupertinoIcons.trash_circle_fill, color: AppColors.error, size: 28),
                                    onPressed: () => setState(() => _foto2Path = null),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _pickImage(2, ImageSource.camera),
                                    icon: const Icon(CupertinoIcons.camera_fill, size: 16),
                                    label: const Text('Kamera'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _pickImage(2, ImageSource.gallery),
                                    icon: const Icon(CupertinoIcons.photo_fill, size: 16),
                                    label: const Text('Galeri'),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
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
}
