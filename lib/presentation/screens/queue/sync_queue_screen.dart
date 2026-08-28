import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../widgets/button.dart';
import '../../../widgets/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paket_provider.dart';

class SyncQueueScreen extends StatelessWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paketProvider = Provider.of<PaketProvider>(context);

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
          'Status Koneksi API Direct Server',
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
              // Direct API Active Banner Card
              IosCard(
                color: AppColors.successBg,
                border: Border.all(color: AppColors.success.withAlpha(77)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.cloud_fill,
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
                            'Integrasi API Live Aktif',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seluruh pengiriman progres lembar kendali langsung diproses dan dikirim ke API Server.',
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

              // Server Details Card
              Text(
                'Rincian Endpoint Active',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 10),
              IosCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Active Server URL', authProvider.baseUrl),
                    const Divider(height: 20),
                    _buildDetailRow('Mode Operasional', 'Direct API (Realtime)'),
                    const Divider(height: 20),
                    _buildDetailRow('Status Akun Token', authProvider.isLoggedIn ? 'Authenticated (Bearer Active)' : 'Not Authenticated'),
                    const Divider(height: 20),
                    _buildDetailRow('Total Paket Pekerjaan', '${paketProvider.totalPackages} Paket'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reload Data Action Button
              IosButton(
                label: 'Muat Ulang Data dari API Server',
                icon: CupertinoIcons.refresh_bold,
                isLoading: paketProvider.isLoading,
                onPressed: () async {
                  await paketProvider.loadPackages();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil diperbarui dari API Server.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
