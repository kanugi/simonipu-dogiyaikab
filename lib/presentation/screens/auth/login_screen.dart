import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/session_manager.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paket_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'roki');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paketProvider = Provider.of<PaketProvider>(context, listen: false);

      try {
        final success = await authProvider.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (success) {
          // Trigger load packages
          paketProvider.loadPackages();
        } else if (mounted) {
          _showErrorDialog(authProvider.errorMessage ?? 'Gagal login. Silakan periksa kredensial Anda.');
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
            Text('Gagal Login', style: GoogleFonts.outfit()),
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

  void _showServerConfigDialog(BuildContext context, AuthProvider authProvider) {
    final currentUrl = authProvider.baseUrl;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          'Pilih Server Environment',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        message: Text(
          'Pilih server API yang akan digunakan untuk proses login dan sinkronisasi data.',
          style: GoogleFonts.inter(fontSize: 12),
        ),
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
                const Text(
                  'Server Utama (Production)\nsimoni-pu.dogiyaikab.go.id',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (currentUrl != SessionManager.defaultBaseUrl) {
                await authProvider.setBaseUrl(SessionManager.defaultBaseUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server berhasil diubah ke Server Utama (Production)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
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
                const Text(
                  'Server Lokal (Development)\nsimoni-pu.khel.my.id',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (currentUrl != SessionManager.localBaseUrl) {
                await authProvider.setBaseUrl(SessionManager.localBaseUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server berhasil diubah ke Server Lokal (Development)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Right Settings Button Action [Butuh diperbaiki, ini hanya untuk debug]
            Positioned(
              top: 8,
              right: 12,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.gear_alt,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  tooltip: 'Pengaturan Server API',
                  onPressed: () => _showServerConfigDialog(context, authProvider),
                ),
              ),
            ),

            // Main Body Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Header Logo & Branding
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/Lambang_Kabupaten_Dogiyai.gif',
                            width: 52,
                            height: 52,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SIMONI PU',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sistem Informasi Monitoring Pekerjaan Umum\n& Penataan Ruang Kab. Dogiyai',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interactive Server Environment Indicator Badge
                        InkWell(
                          onTap: () => _showServerConfigDialog(context, authProvider),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: authProvider.isProductionEnv
                                  ? AppColors.primaryLight
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: authProvider.isProductionEnv
                                    ? AppColors.primary.withAlpha(77)
                                    : AppColors.warning.withAlpha(77),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  authProvider.isProductionEnv
                                      ? CupertinoIcons.cloud_fill
                                      : CupertinoIcons.wrench_fill,
                                  size: 14,
                                  color: authProvider.isProductionEnv
                                      ? AppColors.primary
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Server: ${authProvider.isProductionEnv ? "Production" : "Dev Local"}',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: authProvider.isProductionEnv
                                          ? AppColors.primary
                                          : AppColors.warning,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 12,
                                  color: authProvider.isProductionEnv
                                      ? AppColors.primary
                                      : AppColors.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Form Card
                        IosCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masuk',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 255, 129, 32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              IosTextField(
                                label: 'Username',
                                hint: 'Masukkan Username Petugas',
                                controller: _usernameController,
                                prefixIcon: CupertinoIcons.person_fill,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Username wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              IosTextField(
                                label: 'Kata Sandi',
                                hint: 'Masukkan Kata Sandi',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: CupertinoIcons.lock_fill,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? CupertinoIcons.eye_slash_fill
                                        : CupertinoIcons.eye_fill,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Kata Sandi wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              IosButton(
                                label: 'Masuk',
                                isLoading: authProvider.isLoading,
                                icon: CupertinoIcons.arrow_right_circle_fill,
                                onPressed: _handleLogin,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Dinas Pekerjaan Umum dan Penataan Ruang\nKabupaten Dogiyai, Papua Tengah © 2026',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
