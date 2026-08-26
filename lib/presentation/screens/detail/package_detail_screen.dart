import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/paket_pekerjaan.dart';
import '../../../data/models/progres_lapangan.dart';
import '../../../widgets/card.dart';
import '../../../widgets/status_badge.dart';
import '../../providers/paket_provider.dart';
import '../input/input_progres_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final String packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  late Future<List<ProgresLapangan>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final paketProvider = Provider.of<PaketProvider>(context, listen: false);
    _historyFuture = paketProvider.getHistory(widget.packageId);
  }

  @override
  Widget build(BuildContext context) {
    final paketProvider = Provider.of<PaketProvider>(context);

    // Find package from provider list
    final pkgList =
        paketProvider.packages.where((p) => p.packageId == widget.packageId);
    final PaketPekerjaan? package =
        pkgList.isNotEmpty ? pkgList.first : null;

    if (package == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Paket')),
        body: const Center(child: Text('Paket pekerjaan tidak ditemukan')),
      );
    }

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
          'Rincian Paket & Riwayat',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => InputProgresScreen(package: package),
            ),
          );
          setState(() {
            _loadHistory();
          });
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: Text('Input Progres Baru', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Main Summary Header Card
              IosCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(
                          isSynced: true,
                          customLabel: package.bidang.toUpperCase(),
                          customColor: AppColors.primary,
                          customBgColor: AppColors.primaryLight,
                        ),
                        StatusBadge(isSynced: package.isSynced),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      package.packageId,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.packageName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Values Table
                    _buildInfoRow('Nilai Kontrak', CurrencyFormatter.format(package.nilaiKontrak)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Lokasi Kegiatan', package.lokasi),
                    const SizedBox(height: 8),
                    _buildInfoRow('Penyedia Jasa / Rekanan', package.rekanan),
                    const SizedBox(height: 16),

                    // Overall Physical Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Fisik Terakhir',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${package.progresFisikSaatIni.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: package.progresFisikSaatIni >= 50
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (package.progresFisikSaatIni / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E5EA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          package.progresFisikSaatIni >= 50
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Progress History Timeline Section
              Text(
                'Riwayat Laporan Progres',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<ProgresLapangan>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat laporan progres fisik.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isLast = index == history.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Indicator Node
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: item.isSynced ? AppColors.success : AppColors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 180,
                                  color: const Color(0xFFD1D1D6),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Timeline Item Content Card
                          Expanded(
                            child: IosCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Progres Fisik: ${item.progresFisik.toStringAsFixed(1)}%',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      StatusBadge(isSynced: item.isSynced),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormatter.formatFull(item.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.catatan,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Photo documentation if present
                                  if (item.photoPath != null && item.photoPath!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(item.photoPath!),
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 100,
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(CupertinoIcons.photo, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(CupertinoIcons.location_solid, size: 12, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)} (±${item.gpsAccuracy.toStringAsFixed(1)}m)',
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
