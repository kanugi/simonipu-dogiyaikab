import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/datasources/session_manager.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangeEnvironmentDialog(BuildContext context, AuthProvider authProvider) {
    final currentUrl = authProvider.baseUrl;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Pilih Server Environment', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        message: Text('Mengubah environment akan me-logout sesi aktif dan membawa Anda ke layar Login.', style: GoogleFonts.inter(fontSize: 12)),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: currentUrl == SessionManager.defaultBaseUrl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentUrl == SessionManager.defaultBaseUrl)
                  const Icon(CupertinoIcons.checkmark_alt, size: 18, color: AppColors.primary),
                if (currentUrl == SessionManager.defaultBaseUrl)
                  const SizedBox(width: 8),
                const Text('Server Utama (Production)\nsimoni-pu.dogiyaikab.go.id', textAlign: TextAlign.center),
              ],
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (currentUrl != SessionManager.defaultBaseUrl) {
                _confirmSwitchEnvironment(context, authProvider, SessionManager.defaultBaseUrl);
              }
            },
          ),
          CupertinoActionSheetAction(
            isDefaultAction: currentUrl == SessionManager.localBaseUrl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentUrl == SessionManager.localBaseUrl)
                  const Icon(CupertinoIcons.checkmark_alt, size: 18, color: AppColors.primary),
                if (currentUrl == SessionManager.localBaseUrl)
                  const SizedBox(width: 8),
                const Text('Server Lokal (Development)\nsimoni-pu.khel.my.id', textAlign: TextAlign.center),
              ],
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (currentUrl != SessionManager.localBaseUrl) {
                _confirmSwitchEnvironment(context, authProvider, SessionManager.localBaseUrl);
              }
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _confirmSwitchEnvironment(BuildContext context, AuthProvider authProvider, String targetUrl) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Text('Konfirmasi Ubah ENV', style: GoogleFonts.outfit()),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Mengubah Server API ke:\n$targetUrl\n\nSesi login Anda akan diakhiri dan Anda akan dikembalikan ke halaman login dengan environment baru.',
            style: GoogleFonts.inter(
              fontSize: 13,
              ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Ubah & Logout'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await authProvider.switchEnvironment(targetUrl);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengganti environment: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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

              // Server Environment Section
              Text(
                'Konfigurasi Server API',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),
              IosCard(
                child: Column(
                  children: [
                    _buildMetricRow(
                      icon: CupertinoIcons.cloud_fill,
                      iconColor: authProvider.isProductionEnv ? AppColors.primary : AppColors.warning,
                      title: 'Environment Terpilih',
                      subtitle: authProvider.isProductionEnv ? 'Server Utama (Production)' : 'Server Lokal (Development)',
                      value: authProvider.isProductionEnv ? 'Production' : 'Dev Local',
                    ),
                    const Divider(height: 20),
                    _buildMetricRow(
                      icon: CupertinoIcons.link,
                      iconColor: AppColors.info,
                      title: 'Base Endpoint URL',
                      subtitle: authProvider.baseUrl,
                      value: '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Change Environment Button
              IosButton(
                label: 'Ubah Environment (Switch Server)',
                icon: CupertinoIcons.arrow_2_squarepath,
                isSecondary: true,
                onPressed: () => _showChangeEnvironmentDialog(context, authProvider),
              ),
              const SizedBox(height: 28),

              // Logout Button
              IosButton(
                label: 'Keluar',
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
                          'Apakah Anda yakin ingin keluar?',
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
