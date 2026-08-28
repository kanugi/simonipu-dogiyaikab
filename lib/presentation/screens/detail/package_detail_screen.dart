import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/foto_kendali.dart';
import '../../../data/models/paket_pekerjaan.dart';
import '../../../widgets/card.dart';
import '../../../widgets/status_badge.dart';
import '../../providers/paket_provider.dart';
import '../input/input_progres_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageIdInt;

  const PackageDetailScreen({super.key, required this.packageIdInt});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  late Future<PaketPekerjaan?> _detailFuture;
  late Future<List<FotoKendali>> _fotoHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final paketProvider = Provider.of<PaketProvider>(context, listen: false);
    _detailFuture = paketProvider.getPaketDetail(widget.packageIdInt);
    _fotoHistoryFuture = paketProvider.getPaketFotoHistory(widget.packageIdInt);
  }

  @override
  Widget build(BuildContext context) {
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
          'Detail Paket & Riwayat Kendali',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<PaketPekerjaan?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator(radius: 16));
            }

            final package = snapshot.data;
            if (package == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 48, color: AppColors.warning),
                    const SizedBox(height: 12),
                    Text('Detail Paket Tidak Ditemukan', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _loadData()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Summary Header Card
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
                                if (package.kodePaket.isNotEmpty)
                                  Text(
                                    package.kodePaket,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              package.namaPaket,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (package.rekanan.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                package.rekanan,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Key Values Table
                            _buildInfoRow('Tahun Anggaran', package.tahunAnggaran),
                            const SizedBox(height: 8),
                            _buildInfoRow('Kegiatan', package.kegiatan.isNotEmpty ? package.kegiatan : '-'),
                            const SizedBox(height: 8),
                            _buildInfoRow('Nilai Kontrak', CurrencyFormatter.format(package.nilaiKontrak)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Biaya', CurrencyFormatter.format(package.biaya ?? package.nilaiKontrak)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Realisasi Keuangan', CurrencyFormatter.format(package.realisasiKeuangan)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Sisa Keuangan', CurrencyFormatter.format(package.sisaKeuangan)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Lokasi', package.lokasi ?? '-'),
                            if (package.tglKontrak != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('Tgl Kontrak', '${package.tglKontrak} s/d ${package.batasKontrak ?? '-'}'),
                            ],
                            const SizedBox(height: 16),

                            // Physical Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Realisasi Fisik (realisasi_fisik)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${package.realisasiFisik.toStringAsFixed(1)}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: package.realisasiFisik >= 50
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
                                value: (package.realisasiFisik / 100).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: const Color(0xFFE5E5EA),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  package.realisasiFisik >= 50
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Photo Documentation History Section
                      Text(
                        'Foto Dokumentasi Lembar Kendali',
                        style: AppStyles.titleMedium(context),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<FotoKendali>>(
                        future: _fotoHistoryFuture,
                        builder: (context, fotoSnapshot) {
                          if (fotoSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(child: CupertinoActivityIndicator()),
                            );
                          }

                          final fotoList = fotoSnapshot.data ?? [];
                          if (fotoList.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Belum ada foto lembar kendali yang terverifikasi untuk paket ini.',
                                  textAlign: TextAlign.center,
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
                            itemCount: fotoList.length,
                            itemBuilder: (context, index) {
                              final item = fotoList[index];

                              return IosCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Kendali ID: ${item.kendaliId}',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Verified',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.keterangan.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.keterangan,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),

                                    // Display images
                                    if (item.foto.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: item.foto.map((url) {
                                          final fullUrl = FotoKendali.sanitizeUrl(url);
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              fullUrl,
                                              height: 140,
                                              width: (MediaQuery.of(context).size.width - 64) / 2,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                height: 100,
                                                width: 120,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Icon(CupertinoIcons.photo, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // FAB Input Progres
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => InputProgresScreen(package: package),
                        ),
                      );
                      setState(() {
                        _loadData();
                      });
                    },
                    backgroundColor: AppColors.primary,
                    icon: const Icon(CupertinoIcons.add, color: Colors.white),
                    label: Text(
                      'Input Progres Baru',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
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
