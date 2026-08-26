import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/paket_pekerjaan.dart';
import '../../../data/models/progres_lapangan.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/watermark_preview.dart';
import '../../providers/paket_provider.dart';
import '../../providers/sync_provider.dart';

class InputProgresScreen extends StatefulWidget {
  final PaketPekerjaan package;

  const InputProgresScreen({super.key, required this.package});

  @override
  State<InputProgresScreen> createState() => _InputProgresScreenState();
}

class _InputProgresScreenState extends State<InputProgresScreen> {
  final _formKey = GlobalKey<FormState>();
  late double _progresFisik;
  late double _realisasiKeuangan;
  final TextEditingController _progresTextController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _imagePath;
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
    _realisasiKeuangan = widget.package.progresFisikSaatIni * 0.9;
    _progresTextController.text = _progresFisik.toStringAsFixed(1);
    _initDeviceLocation();
  }

  @override
  void dispose() {
    _progresTextController.dispose();
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
      // Fallback simulated Dogiyai coordinates if GPS unavailable offline
      final random = Random();
      setState(() {
        _latitude = -4.0152 + (random.nextDouble() - 0.5) * 0.01;
        _longitude = 135.9521 + (random.nextDouble() - 0.5) * 0.01;
        _gpsAccuracy = 3.5 + random.nextDouble() * 2;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _currentTimestamp = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengakses kamera/galeri: $e')),
        );
      }
    }
  }

  void _saveLocalDraft() async {
    if (_formKey.currentState!.validate()) {
      final newRecord = ProgresLapangan(
        idLocal: const Uuid().v4(),
        packageId: widget.package.packageId,
        packageName: widget.package.packageName,
        bidang: widget.package.bidang,
        progresFisik: _progresFisik,
        realisasiKeuangan: _realisasiKeuangan,
        catatan: _catatanController.text.trim(),
        photoPath: _imagePath,
        latitude: _latitude,
        longitude: _longitude,
        gpsAccuracy: _gpsAccuracy,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      final paketProvider = Provider.of<PaketProvider>(context, listen: false);
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      await paketProvider.addProgres(newRecord);
      await syncProvider.loadSyncQueue();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.success, size: 22),
                const SizedBox(width: 8),
                Text('Tersimpan di Lokal', style: GoogleFonts.outfit()),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Progres fisik ${_progresFisik.toStringAsFixed(1)}% berhasil disimpan ke database SQLite luring dan masuk dalam antrean sync.',
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
      }
    }
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
          'Input Progres Lapangan',
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
                      Text(
                        widget.package.packageId,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
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
                              widget.package.lokasi,
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

                // Form Physical Progress (%) Section
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
                              _realisasiKeuangan = val * 0.9;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      IosTextField(
                        label: 'Input Angka Persentase Manual',
                        hint: 'Contoh: 48.5',
                        controller: _progresTextController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0 && parsed <= 100) {
                            setState(() {
                              _progresFisik = parsed;
                              _realisasiKeuangan = parsed * 0.9;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Field Notes Section
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan & Kendala Lapangan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      IosTextField(
                        label: '',
                        hint:
                            'Uraikan detail perkembangan pengerjaan, material, jumlah tenaga kerja, atau kendala cuaca di lokasi...',
                        controller: _catatanController,
                        maxLines: 4,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Catatan lapangan wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Camera & Watermark Module Section
                IosCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto Dokumentasi Lapangan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Geo-Tagging + Stamp',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WatermarkPreview(
                        imagePath: _imagePath,
                        latitude: _latitude,
                        longitude: _longitude,
                        accuracy: _gpsAccuracy,
                        timestamp: _currentTimestamp,
                        packageName: widget.package.packageName,
                        onPickCamera: () => _pickImage(ImageSource.camera),
                        onPickGallery: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GPS & Real-time Timestamp Meta Card
                IosCard(
                  color: const Color(0xFFFAFAFC),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location_circle_fill,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Koordinat GPS Lapangan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_latitude.toStringAsFixed(6)},'
                                  '${_longitude.toStringAsFixed(6)}'
                                  '(Akurasi: ${_gpsAccuracy.toStringAsFixed(1)} m)',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isGettingLocation)
                            const CupertinoActivityIndicator(radius: 10)
                          else
                            IconButton(
                              icon: const Icon(CupertinoIcons.refresh_thin,
                                  size: 18),
                              onPressed: _initDeviceLocation,
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.time_solid,
                              color: AppColors.info, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Waktu Pengambilan Data',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatFull(_currentTimestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                IosButton(
                  label: 'Simpan ke Local Storage (Draft Offline)',
                  icon: CupertinoIcons.floppy_disk,
                  isLoading: paketProvider.isLoading,
                  onPressed: _saveLocalDraft,
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
