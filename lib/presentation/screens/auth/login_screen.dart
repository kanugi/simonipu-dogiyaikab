import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../../widgets/text_field.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/main_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController(text: '19880412 201201 1 002');
  final _passwordController = TextEditingController(text: 'pupr12345');
  // bool _isOfflineActive = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _nipController.text,
        _passwordController.text,
      );

      if (mounted && success) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => const MainDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Logo & Branding
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/Lambang_Kabupaten_Dogiyai.gif',
                        width: 52,
                        height: 52,
                      )
                      // child: const Icon(
                      //   CupertinoIcons.building_2_fill,
                      //   size: 52,
                      //   color: AppColors.primary,
                      // ),
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
                    const SizedBox(height: 32),

                    // Offline Status Badge Bar
                    // IosCard(
                    //   margin: const EdgeInsets.only(bottom: 20),
                    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    //   color: AppColors.successBg,
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         padding: const EdgeInsets.all(6),
                    //         decoration: const BoxDecoration(
                    //           color: AppColors.success,
                    //           shape: BoxShape.circle,
                    //         ),
                    //         child: const Icon(
                    //           CupertinoIcons.wifi_slash,
                    //           size: 16,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               'Modus Luring Active',
                    //               style: GoogleFonts.inter(
                    //                 fontSize: 13,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: AppColors.success,
                    //               ),
                    //             ),
                    //             Text(
                    //               'Penyimpanan database lokal SQLite aktif',
                    //               style: GoogleFonts.inter(
                    //                 fontSize: 11,
                    //                 color: AppColors.textSecondary,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //       CupertinoSwitch(
                    //         value: _isOfflineActive,
                    //         activeTrackColor: AppColors.success,
                    //         onChanged: (val) {
                    //           setState(() {
                    //             _isOfflineActive = val;
                    //           });
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    // ),

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
                            label: 'NIP / Username',
                            hint: 'Masukkan NIP Petugas',
                            controller: _nipController,
                            prefixIcon: CupertinoIcons.person_fill,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'NIP / Username wajib diisi';
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
                            label: 'Masuk System',
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
      ),
    );
  }
}
