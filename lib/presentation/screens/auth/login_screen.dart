import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
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
  String? _loginErrorMessage;
  bool _hasLoginError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearLoginError() {
    if (_hasLoginError || _loginErrorMessage != null) {
      setState(() {
        _hasLoginError = false;
        _loginErrorMessage = null;
      });
    }
  }

  void _handleLogin() async {
    _clearLoginError();

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
          paketProvider.loadPackages();
        } else if (mounted) {
          final rawMsg = authProvider.errorMessage ?? '';
          final lowerMsg = rawMsg.toLowerCase();
          final isCredentialError = lowerMsg.contains('tidak sesuai') ||
              lowerMsg.contains('salah') ||
              lowerMsg.contains('unauthorized') ||
              lowerMsg.contains('kredensial') ||
              lowerMsg.contains('periksa username');

          setState(() {
            _hasLoginError = true;
            _loginErrorMessage = isCredentialError
                ? 'Kombinasi Username dan Kata Sandi tidak sesuai. Silahkan periksa kembali akun Anda.'
                : (rawMsg.isNotEmpty ? rawMsg : 'Kombinasi Username dan Kata Sandi tidak sesuai.');
          });

          // Jika terjadi error jaringan/koneksi server, tampilkan dialog error detail
          if (!isCredentialError && rawMsg.isNotEmpty) {
            _showErrorDialog(rawMsg);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasLoginError = true;
            _loginErrorMessage = 'Terjadi kesalahan sistem saat proses login.';
          });
          _showErrorDialog('Terjadi kesalahan: $e');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 10),
            Text('Gagal Login', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tutup'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context, AuthProvider authProvider) {
    final currentUrl = authProvider.baseUrl;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Pilih Server Environment',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih server API yang akan digunakan untuk proses login dan sinkronisasi data.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Server Production Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: currentUrl == SessionManager.defaultBaseUrl ? AppColors.primary : AppColors.borderLight,
                    width: currentUrl == SessionManager.defaultBaseUrl ? 1.5 : 1,
                  ),
                ),
                tileColor: currentUrl == SessionManager.defaultBaseUrl ? AppColors.primaryLight : Colors.white,
                leading: Icon(
                  Icons.cloud_rounded,
                  color: currentUrl == SessionManager.defaultBaseUrl ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  'Server Utama (Production)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text('simoni-pu.dogiyaikab.go.id', style: TextStyle(fontSize: 12)),
                trailing: currentUrl == SessionManager.defaultBaseUrl
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (currentUrl != SessionManager.defaultBaseUrl) {
                    await authProvider.setBaseUrl(SessionManager.defaultBaseUrl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Server dialihkan ke Production'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),

              // Server Development Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: currentUrl == SessionManager.localBaseUrl ? AppColors.accent : AppColors.borderLight,
                    width: currentUrl == SessionManager.localBaseUrl ? 1.5 : 1,
                  ),
                ),
                tileColor: currentUrl == SessionManager.localBaseUrl ? AppColors.accentLight : Colors.white,
                leading: Icon(
                  Icons.developer_mode_rounded,
                  color: currentUrl == SessionManager.localBaseUrl ? AppColors.accent : AppColors.textSecondary,
                ),
                title: Text(
                  'Server Lokal (Development)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text('simoni-pu.khel.my.id', style: TextStyle(fontSize: 12)),
                trailing: currentUrl == SessionManager.localBaseUrl
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.accent)
                    : null,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (currentUrl != SessionManager.localBaseUrl) {
                    await authProvider.setBaseUrl(SessionManager.localBaseUrl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Server dialihkan ke Development'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── 1. Base Gradient Canvas Background ──────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEBF2F7), // Soft cool grey-blue
                      Color(0xFFF8FAFC), // Slate 50
                      Color(0xFFF1F5F9), // Slate 100
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // ── 2. Subtle Civil Engineering / Blueprint Dot Grid Matrix ─────
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  dotColor: AppColors.primary.withAlpha(12),
                  spacing: 24.0,
                ),
              ),
            ),

            // ── 3. Ambient Glowing Radial Orbs (Bottom Decorations) ─────────
            // Soft PU Orange Warm Ambient Glow (Bottom Right)
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withAlpha(28),
                      AppColors.accent.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // Soft Ocean Blue Ambient Glow (Bottom Left)
            Positioned(
              bottom: 80,
              left: -70,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withAlpha(22),
                      AppColors.primary.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle Architectural Concentric Line Arc (Bottom Left Corner)
            Positioned(
              bottom: -35,
              left: -35,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(24),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // ── 4. Main Scrollable Content ──────────────────────────────────
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Curved Wave Hero Banner
                    _buildCurvedHeader(context, authProvider, size),

                    // Overlapping Login Card Container
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            children: [
                              _buildLoginFormCard(authProvider),
                              const SizedBox(height: 16),
                              _buildFooter(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header lengkung dinamis dengan gradasi PU-SIMONI, gelombang ganda, dan logo
  Widget _buildCurvedHeader(BuildContext context, AuthProvider authProvider, Size size) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = 280.0 + topPadding;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Secondary Accent Wave Layer (Golden Orange Tint Behind)
          Positioned.fill(
            child: ClipPath(
              clipper: _SecondaryWaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark.withAlpha(160),
                      AppColors.accent.withAlpha(100),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Primary Front Wave Layer (Header Gradient Khas SIMONI PU)
          Positioned.fill(
            child: ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: Stack(
                  children: [
                    // Decorative Background Translucent Geometric Circle (Top Right)
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(26),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),

                    // Translucent Ring (Top Left)
                    Positioned(
                      top: 40,
                      left: -50,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(10),
                        ),
                      ),
                    ),

                    // Content Container inside Header Wave
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Column(
                          children: [
                            // Top Bar: Tombol Settings Icon Gerigi di Kanan Atas
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                tooltip: 'Pengaturan Server API',
                                onPressed: () => _showServerConfigDialog(context, authProvider),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Branding Logo Container
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/logo-simoni-pu.png',
                                  width: 66,
                                  height: 66,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // App Title
                            Text(
                              'SIMONI PU',
                              style: GoogleFonts.outfit(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // App Subtitle
                            Text(
                              'Sistem Informasi Monitoring Pekerjaan Umum',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withAlpha(220),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Form Login Berisi Input Username, Password, Alert Error, dan Tombol Masuk
  Widget _buildLoginFormCard(AuthProvider authProvider) {
    return SimoniCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 22,
      customShadow: AppStyles.floatingShadow,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Masuk ke Akun',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 4),
            // Padding(
            //   padding: const EdgeInsets.only(left: 12.0),
            //   child: Text(
            //     'Silakan masukkan kredensial akun petugas Anda',
            //     style: GoogleFonts.inter(
            //       fontSize: 12,
            //       color: AppColors.textSecondary,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 18),

            // Alert Banner Kondisi Gagal Login
            if (_loginErrorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(90), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autentikasi Gagal',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _loginErrorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _clearLoginError,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SimoniTextField(
              label: 'Username',
              hint: 'Masukkan Username Petugas',
              controller: _usernameController,
              prefixIcon: Icons.person_rounded,
              hasError: _hasLoginError,
              onChanged: (_) => _clearLoginError(),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Username wajib diisi';
                }
                if (val.trim().length < 3) {
                  return 'Username minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            SimoniTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan Kata Sandi',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_rounded,
              hasError: _hasLoginError,
              onChanged: (_) => _clearLoginError(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
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
                if (val.length < 3) {
                  return 'Kata Sandi minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            SimoniButton(
              label: 'Masuk',
              isLoading: authProvider.isLoading,
              // icon: Icons.login_rounded,
              gradient: AppColors.headerGradient,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  /// Bagian Footer dengan identitas instansi & tahun rilis
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Dinas Pekerjaan Umum dan Penataan Ruang\nKabupaten Dogiyai, Papua Tengah © 2026',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight, width: 0.6),
          ),
          child: Text(
            'v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS FOR BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

/// Painter untuk membuat pattern blueprint dot grid halus khas teknik sipil & konstruksi PU
class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  const _DotGridPainter({
    required this.dotColor,
    this.spacing = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor || oldDelegate.spacing != spacing;
}

/// Clipper untuk gelombang header utama (Primary Wave)
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);

    final firstControlPoint = Offset(size.width * 0.28, size.height);
    final firstEndPoint = Offset(size.width * 0.58, size.height - 24);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.88, size.height - 48);
    final secondEndPoint = Offset(size.width, size.height - 16);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Clipper untuk aksen gelombang sekunder di belakang header (Secondary Wave)
class _SecondaryWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 18);

    final firstControlPoint = Offset(size.width * 0.38, size.height - 48);
    final firstEndPoint = Offset(size.width * 0.70, size.height - 10);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.92, size.height + 10);
    final secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
