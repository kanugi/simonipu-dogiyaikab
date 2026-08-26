import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/status_badge.dart';
import '../../providers/paket_provider.dart';
import '../../providers/sync_provider.dart';

class SyncQueueScreen extends StatelessWidget {
  const SyncQueueScreen({super.key});

  void _handleSimulatedSync(BuildContext context) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final paketProvider = Provider.of<PaketProvider>(context, listen: false);

    final queueCountBefore = syncProvider.queueCount;

    if (queueCountBefore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data progres lokal sudah tersinkronisasi.'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    final countSynced = await syncProvider.simulateSyncData();
    await paketProvider.loadPackages();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$countSynced Data Berhasil Tersinkronisasi ke Server Pusat SIMONI PU',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncProvider = Provider.of<SyncProvider>(context);

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
          'Antrean Sinkronisasi (Queue)',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Queue Status Overview Banner Card
              IosCard(
                color: syncProvider.queueCount > 0 ? AppColors.warningBg : AppColors.successBg,
                border: Border.all(
                  color: (syncProvider.queueCount > 0 ? AppColors.warning : AppColors.success).withAlpha(77),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: syncProvider.queueCount > 0 ? AppColors.warning : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        syncProvider.queueCount > 0
                            ? CupertinoIcons.arrow_2_circlepath_circle_fill
                            : CupertinoIcons.checkmark_shield_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncProvider.queueCount > 0
                                ? '${syncProvider.queueCount} Laporan Tertunda'
                                : 'Semua Laporan Tersinkron',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: syncProvider.queueCount > 0 ? AppColors.warning : AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            syncProvider.queueCount > 0
                                ? 'Data tersimpan di SQLite lokal dan siap dikirim ke server pusat SIMONI PU.'
                                : 'Tidak ada laporan progres fisik yang tertunda di local storage.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sync Action Trigger Button
              IosButton(
                label: 'Sync Data ke Server Pusat (Simulasi)',
                icon: CupertinoIcons.cloud_upload_fill,
                isLoading: syncProvider.isSyncing,
                onPressed: syncProvider.queueCount == 0
                    ? null
                    : () => _handleSimulatedSync(context),
              ),
              const SizedBox(height: 24),

              // Queue List Items Title
              Text(
                'Daftar Laporan Dalam Antrean (${syncProvider.queueCount})',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 12),

              if (syncProvider.unsyncedList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(CupertinoIcons.checkmark_circle_fill, size: 48, color: AppColors.success),
                        const SizedBox(height: 10),
                        Text(
                          'Antrean Kosong',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semua progres pekerjaan lapangan telah terkirim.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: syncProvider.unsyncedList.length,
                  itemBuilder: (context, index) {
                    final item = syncProvider.unsyncedList[index];

                    return IosCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.packageId,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const StatusBadge(isSynced: false),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.packageName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progres Fisik Ditambahkan: ${item.progresFisik.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                DateFormatter.formatShortDate(item.timestamp),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (item.catatan.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Catatan: "${item.catatan}"',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
