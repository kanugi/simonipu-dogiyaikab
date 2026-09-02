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
import '../edit/edit_kendali_screen.dart';
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
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 48,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detail Paket Tidak Ditemukan',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                                  'Realisasi Fisik',
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

                          if (fotoSnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(CupertinoIcons.exclamationmark_circle,
                                        color: AppColors.warning, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gagal memuat foto: ${fotoSnapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                          fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
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
                              final bool isPending = item.status.toLowerCase() == 'pending';

                              return IosCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Kendali ID, Edit/Delete Action Buttons, & Status Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Kendali #${item.kendaliId}',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Tombol Edit dan Hapus hanya muncul jika status == Pending
                                            if (isPending) ...[
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(6),
                                                  onTap: () async {
                                                    final updated = await Navigator.of(context).push(
                                                      CupertinoPageRoute(
                                                        builder: (_) => EditKendaliScreen(
                                                          package: package,
                                                          kendaliItem: item,
                                                        ),
                                                      ),
                                                    );
                                                    if (updated == true || mounted) {
                                                      setState(() {
                                                        _loadData();
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(CupertinoIcons.pencil, size: 12, color: AppColors.primary),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Edit',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(6),
                                                  onTap: () => _confirmDeleteKendali(item),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(CupertinoIcons.trash, size: 12, color: AppColors.error),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Hapus',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.error,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: item.status.toLowerCase() == 'approved'
                                                    ? AppColors.successBg
                                                    : const Color(0xFFFFF3CD),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.status.isNotEmpty
                                                    ? item.status.toUpperCase()
                                                    : 'VERIFIED',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.status.toLowerCase() == 'approved'
                                                      ? AppColors.success
                                                      : const Color(0xFF856404),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                    const SizedBox(height: 12),

                                    // Tampilkan semua foto secara dinamis
                                    if (item.fotoItems.isEmpty)
                                      Center(
                                        child: Text(
                                          'Tidak ada foto tersedia.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (int i = 0; i < item.fotoItems.length; i++) ...[
                                            if (i > 0) const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildPhotoCard(
                                                url: item.fotoItems[i].url,
                                                label: 'Foto ${i + 1}',
                                                info: item.fotoItems[i].info,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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

  /// Helper widget untuk render foto per item beserta label & deskripsi infonya
  Widget _buildPhotoCard({
    required String url,
    required String label,
    required String info,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Stack(
              children: [
                Image.network(
                  FotoKendali.sanitizeUrl(url),
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 130,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(CupertinoIcons.photo, color: Colors.grey, size: 30),
                    ),
                  ),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 130,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.info_circle,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    info.isNotEmpty ? info : 'Tanpa Keterangan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: info.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteKendali(FotoKendali item) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.trash_fill, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text('Hapus Kendali #${item.kendaliId}', style: GoogleFonts.outfit()),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Apakah Anda yakin ingin menghapus lembar kendali ini? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final paketProvider = Provider.of<PaketProvider>(context, listen: false);
              final success = await paketProvider.deleteKendali(item.kendaliId);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lembar kendali berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {
                    _loadData();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(paketProvider.errorMessage ?? 'Gagal menghapus lembar kendali.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}