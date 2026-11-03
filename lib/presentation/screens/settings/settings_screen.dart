import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paket_provider.dart';
import '../../providers/sync_provider.dart';
import '../queue/sync_queue_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
          'Pengaturan',
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
              // Profile Header Card
              IosCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Role: ${authProvider.roleName}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Username: @${authProvider.username}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (authProvider.user != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: ${authProvider.user!.id}',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sinkronisasi & Antrean Offline
              Text(
                'Sinkronisasi & Antrean',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),
              IosCard(
                child: Consumer<SyncProvider>(
                  builder: (context, syncProv, _) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: syncProv.queueCount > 0 ? const Color(0xFFFFFBEB) : AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                syncProv.queueCount > 0 ? Icons.cloud_upload_rounded : Icons.cloud_rounded,
                                color: syncProv.queueCount > 0 ? AppColors.warning : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Antrean Offline & Sync',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    syncProv.queueCount > 0
                                        ? '${syncProv.queueCount} data menunggu sinkronisasi'
                                        : 'Semua data telah tersinkronisasi',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (syncProv.queueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${syncProv.queueCount}',
                                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Server Environment Section (Read-Only Status)
              Text(
                'Konfigurasi Server API',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),
              IosCard(
                child: Column(
                  children: [
                    // _buildMetricRow(
                    //   icon: Icons.cloud_rounded,
                    //   iconColor: authProvider.isProductionEnv ? AppColors.primary : AppColors.warning,
                    //   title: 'Environment Terpilih',
                    //   subtitle: authProvider.isProductionEnv ? 'Server Utama (Production)' : 'Server Lokal (Development)',
                    //   value: authProvider.isProductionEnv ? 'Production' : 'Dev Local',
                    // ),
                    // const Divider(height: 20),
                    _buildMetricRow(
                      icon: Icons.link_rounded,
                      iconColor: AppColors.info,
                      title: 'Base Endpoint URL',
                      subtitle: authProvider.baseUrl,
                      value: '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Read-Only Server Info Notice Box
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFF2F2F7),
              //     borderRadius: BorderRadius.circular(10),
              //     border: Border.all(color: const Color(0xFFE5E5EA)),
              //   ),
              //   child: Row(
              //     children: [
              //       const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           'Untuk mengubah server API, silakan keluar (logout) terlebih dahulu dan atur melalui menu pengaturan di halaman Login.',
              //           style: GoogleFonts.inter(
              //             fontSize: 11,
              //             color: AppColors.textSecondary,
              //             height: 1.3,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),

              // Logout Button
              IosButton(
                label: 'Keluar',
                icon: Icons.logout_rounded,
                isDanger: true,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
                      title: Text('Konfirmasi Logout', style: GoogleFonts.outfit()),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Apakah Anda yakin ingin keluar?',
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
            child: const Text('Keluar'),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            if (context.mounted) {
                              Provider.of<PaketProvider>(context, listen: false).clearPackages();
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                            await authProvider.logout();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
