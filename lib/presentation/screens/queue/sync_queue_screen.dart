import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paket_provider.dart';
import '../../providers/sync_provider.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<SyncProvider>(context, listen: false).loadSyncQueue();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormatter.formatShortDate(dt);
  }

  void _confirmDelete(BuildContext context, String clientUuid, String namaPaket) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text('Hapus Antrean', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Apakah Anda yakin ingin menghapus laporan offline untuk "$namaPaket"? Data yang belum tersinkronisasi akan dihapus permanen.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final syncProvider = Provider.of<SyncProvider>(context, listen: false);
              final ok = await syncProvider.deleteQueueItem(clientUuid);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Antrean berhasil dihapus.' : 'Gagal menghapus antrean.'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _retrySingle(BuildContext context, String clientUuid) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final paketProvider = Provider.of<PaketProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Mencoba mengirimkan data ke server...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await syncProvider.retrySingleItem(clientUuid);
    if (success) {
      await paketProvider.loadPackages();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data berhasil disinkronkan ke server!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(syncProvider.lastErrorMessage ?? 'Gagal sinkronisasi. Cek sinyal internet Anda.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _syncAll(BuildContext context) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final paketProvider = Provider.of<PaketProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Memulai sinkronisasi seluruh antrean...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await syncProvider.performBiDirectionalSync();
    if (success) {
      await paketProvider.loadPackages();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Seluruh data berhasil disinkronkan ke server!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(syncProvider.lastErrorMessage ?? 'Sinkronisasi gagal. Pastikan terhubung internet.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final syncProvider = Provider.of<SyncProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Antrean Sinkronisasi Offline',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Segarkan Antrean',
            onPressed: () => syncProvider.loadSyncQueue(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => syncProvider.loadSyncQueue(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Header Status Card ─────────────────────────────────────────
              IosCard(
                color: syncProvider.queueCount > 0 ? const Color(0xFFFFFBEB) : AppColors.successBg,
                border: Border.all(
                  color: (syncProvider.queueCount > 0 ? AppColors.warning : AppColors.success).withAlpha(77),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: syncProvider.queueCount > 0 ? AppColors.warning : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        syncProvider.queueCount > 0 ? Icons.cloud_upload_rounded : Icons.cloud_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncProvider.queueCount > 0
                                ? '${syncProvider.queueCount} Laporan Tertahan Offline'
                                : 'Semua Data Tersinkronisasi',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: syncProvider.queueCount > 0 ? const Color(0xFFB45309) : AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Text(
                          //   syncProvider.queueCount > 0
                          //       ? 'Data disimpan lokal di perangkat. Tekan "Sinkronkan Semua" saat ada koneksi internet.'
                          //       : 'Tidak ada laporan yang tertahan. Perangkat sinkron dengan server.',
                          //   style: GoogleFonts.inter(
                          //     fontSize: 12,
                          //     color: AppColors.textSecondary,
                          //   ),
                          // ),
                          if (syncProvider.lastSyncTime != null && syncProvider.lastSyncTime!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Terakhir Sync: ${_formatDate(syncProvider.lastSyncTime)}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tombol Sinkronkan Semua (Jika ada antrean) ───────────────────
              if (syncProvider.queueCount > 0) ...[
                IosButton(
                  label: syncProvider.isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Semua Sekarang (${syncProvider.queueCount})',
                  icon: Icons.sync_rounded,
                  isLoading: syncProvider.isSyncing,
                  onPressed: syncProvider.isSyncing ? null : () => _syncAll(context),
                ),
                const SizedBox(height: 16),
              ],

              // ── Daftar Item Antrean ─────────────────────────────────────────
              Text(
                'Daftar Antrean Kendali Offline',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),

              if (syncProvider.queueCount == 0)
                _buildEmptyState()
              else
                ...syncProvider.unsyncedItems.map((item) => _buildQueueItemCard(context, item, syncProvider.isSyncing)),

              const SizedBox(height: 24),

              // ── Info Server & Environment ──────────────────────────────────
              SimoniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Koneksi API',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow('Endpoint API', authProvider.baseUrl),
                    const SizedBox(height: 8),
                    _buildInfoRow('Status Autentikasi', authProvider.isLoggedIn ? 'Aktif (Bearer Token)' : 'Belum Login'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Engine Sinkronisasi', 'Bi-Directional PUSH & PULL (/api/v1/sync)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Antrean Bersih',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Text(
            //   'Seluruh laporan kendali telah terunggah ke database server pusat. Ketika Anda mengisi laporan tanpa internet, data akan muncul di sini.',
            //   textAlign: TextAlign.center,
            //   style: GoogleFonts.inter(
            //     fontSize: 12,
            //     color: AppColors.textSecondary,
            //     height: 1.4,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItemCard(BuildContext context, Map<String, dynamic> item, bool isSyncingGlobal) {
    final clientUuid = item['client_uuid']?.toString() ?? '';
    final namaPaket = item['nama_paket']?.toString() ?? 'Paket #${item['proyekid']}';
    final majufreal = (item['majufreal'] is num) ? (item['majufreal'] as num).toDouble() : 0.0;
    final majukeuangan = (item['majukeuangan'] is num) ? (item['majukeuangan'] as num).toDouble() : 0.0;
    final keterangan = item['keterangan']?.toString() ?? '';
    final foto1Path = item['foto1_local_path']?.toString() ?? '';
    final foto2Path = item['foto2_local_path']?.toString() ?? '';
    final syncStatus = item['sync_status']?.toString() ?? 'pending_sync';
    final syncError = item['sync_error']?.toString();
    final createdAt = item['created_at']?.toString() ?? '';

    final isFailed = syncStatus == 'failed_validation';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailed ? AppColors.error.withAlpha(100) : const Color(0xFFE5E5EA),
          width: isFailed ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Judul & Badge Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaPaket,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFailed ? AppColors.errorBg : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isFailed ? AppColors.error.withAlpha(80) : AppColors.warning.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFailed ? Icons.error_rounded : Icons.schedule_rounded,
                        size: 11,
                        color: isFailed ? AppColors.error : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFailed ? 'Gagal Validasi' : 'Menunggu Sync',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFailed ? AppColors.error : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nilai Progres & Keuangan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progres Fisik', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        Text('${majufreal.toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE5E5EA)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nominal Tagihan', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        Text(CurrencyFormatter.format(majukeuangan),
                            style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (keterangan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: $keterangan',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Preview Foto Thumbnail
            const SizedBox(height: 10),
            Row(
              children: [
                if (foto1Path.isNotEmpty) _buildPhotoThumb(foto1Path, 'Foto 1'),
                const SizedBox(width: 8),
                if (foto2Path.isNotEmpty) _buildPhotoThumb(foto2Path, 'Foto 2'),
              ],
            ),

            // Pesan Error jika Gagal
            if (isFailed && syncError != null && syncError.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        syncError,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 20),

            // Tombol Aksi (Coba Lagi & Hapus)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Hapus
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                  label: Text('Hapus Draf', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                  onPressed: isSyncingGlobal ? null : () => _confirmDelete(context, clientUuid, namaPaket),
                ),
                const SizedBox(width: 8),
                // Tombol Coba Kirim Ulang
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text('Kirim Ulang', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: isSyncingGlobal ? null : () => _retrySingle(context, clientUuid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumb(String filePath, String label) {
    final file = File(filePath);
    final exists = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF2F2F7),
        child: exists
            ? Image.file(file, fit: BoxFit.cover)
            : Center(
                child: Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
