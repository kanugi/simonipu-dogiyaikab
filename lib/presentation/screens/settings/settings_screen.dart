import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pengaturan & Sesi',
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
                        CupertinoIcons.person_fill,
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
                            authProvider.jabatan,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NIP: ${authProvider.nip}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Storage & Cache Diagnostics Section
              Text(
                'Kapasitas & Penyimpanan Lokal',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),
              IosCard(
                child: Column(
                  children: [
                    _buildMetricRow(
                      icon: CupertinoIcons.circle_grid_hex_fill,
                      iconColor: AppColors.info,
                      title: 'Ukuran Database SQLite',
                      subtitle: 'Penyimpanan terstruktur luring',
                      value: '${syncProvider.dbSizeKb} KB',
                    ),
                    const Divider(height: 20),
                    _buildMetricRow(
                      icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                      iconColor: AppColors.primary,
                      title: 'Foto Dokumentasi Tersimpan',
                      subtitle: 'Hasil tangkapan kamera ber-geotag',
                      value: '${syncProvider.photoCount} Foto',
                    ),
                    const Divider(height: 20),
                    _buildMetricRow(
                      icon: CupertinoIcons.wifi_slash,
                      iconColor: AppColors.success,
                      title: 'Mode Operasional',
                      subtitle: 'Offline-First Full Storage',
                      value: 'Aktif',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clear Cache Button
              IosButton(
                label: 'Hapus Cache Foto Temporer',
                icon: CupertinoIcons.trash_fill,
                isSecondary: true,
                onPressed: () async {
                  await syncProvider.clearPhotoCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache foto temporer berhasil dibersihkan.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 28),

              // Agency Info Section
              // IosCard(
              //   color: const Color(0xFFFAFAFC),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'SIMONI PU v1.0.0 (Offline Build)',
              //         style: GoogleFonts.outfit(
              //           fontSize: 14,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         'Sistem Informasi Monitoring Pekerjaan Umum dan Penataan Ruang Dinas PUPR Kabupaten Dogiyai, Provinsi Papua Tengah.',
              //         style: GoogleFonts.inter(
              //           fontSize: 12,
              //           color: AppColors.textSecondary,
              //           height: 1.4,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 28),

              // Logout Button
              IosButton(
                label: 'Keluar / Logout Sesi',
                icon: CupertinoIcons.power,
                isDanger: true,
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text('Konfirmasi Logout', style: GoogleFonts.outfit()),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Apakah Anda yakin ingin keluar dari akun petugas? Data antrean lokal tetap tersimpan.',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Batal'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Keluar'),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                CupertinoPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
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
              ),
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
