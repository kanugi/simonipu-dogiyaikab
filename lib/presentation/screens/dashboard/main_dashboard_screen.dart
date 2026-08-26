import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/paket_pekerjaan.dart';
import '../../../widgets/card.dart';
import '../../../widgets/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paket_provider.dart';
import '../../providers/sync_provider.dart';
import '../detail/package_detail_screen.dart';
import '../input/input_progres_screen.dart';
import '../queue/sync_queue_screen.dart';
import '../settings/settings_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['Semua', 'Jalan', 'Jembatan', 'Irigasi', 'Perumahan'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paketProvider = Provider.of<PaketProvider>(context);
    final syncProvider = Provider.of<SyncProvider>(context);

    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(CupertinoIcons.person_fill, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        authProvider.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormatter.formatDateOnly(DateTime.now()),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Offline Active Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Mode Luring',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Queue Sync Icon Shortcut
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_2_circlepath, color: AppColors.primary),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const SyncQueueScreen()),
                        );
                      },
                    ),
                    if (syncProvider.queueCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${syncProvider.queueCount}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Settings Shortcut
                IconButton(
                  icon: const Icon(CupertinoIcons.gear_alt, color: AppColors.textSecondary),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await paketProvider.loadPackages();
            await syncProvider.loadSyncQueue();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Monitoring Progres Pekerjaan',
                  style: AppStyles.titleLarge(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dinas PUPR Kabupaten Dogiyai',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Summary Metrics Cards (Adaptive Grid 3 Column / Responsive Row)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth = constraints.maxWidth >= 600
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSummaryCard(
                          context,
                          width: cardWidth,
                          title: 'Total Paket',
                          value: '${paketProvider.totalPackages}',
                          subtitle: 'Terunduh di Lokal',
                          icon: CupertinoIcons.doc_text_fill,
                          iconColor: AppColors.primary,
                          bgColor: AppColors.primaryLight,
                        ),
                        _buildSummaryCard(
                          context,
                          width: cardWidth,
                          title: 'Antrean Sync',
                          value: '${paketProvider.unsyncedCount}',
                          subtitle: 'Laporan Belum Ter-upload',
                          icon: CupertinoIcons.clock_fill,
                          iconColor: AppColors.warning,
                          bgColor: AppColors.warningBg,
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const SyncQueueScreen()),
                            );
                          },
                        ),
                        _buildSummaryCard(
                          context,
                          width: constraints.maxWidth >= 600 ? cardWidth : constraints.maxWidth,
                          title: 'Rata-rata Progres',
                          value: '${paketProvider.averageProgress.toStringAsFixed(1)}%',
                          subtitle: 'Fisik Lapangan',
                          icon: CupertinoIcons.chart_bar_fill,
                          iconColor: AppColors.success,
                          bgColor: AppColors.successBg,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => paketProvider.searchPackages(val),
                    decoration: InputDecoration(
                      hintText: 'Cari paket pekerjaan, kode, atau lokasi...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                      prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                paketProvider.searchPackages('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filter Category Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = paketProvider.selectedCategory == cat;

                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.borderLight,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            paketProvider.filterByCategory(cat);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Package List Section Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Paket Pekerjaan (${paketProvider.packages.length})',
                      style: AppStyles.titleMedium(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kabupaten Dogiyai',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Adaptive Package Cards Grid / List
                paketProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CupertinoActivityIndicator(radius: 16),
                        ),
                      )
                    : paketProvider.packages.isEmpty
                        ? _buildEmptyState()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (isTablet) {
                                // 2-Column Grid on Tablet
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.35,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: paketProvider.packages.length,
                                  itemBuilder: (context, index) {
                                    return _buildPackageCard(
                                      context,
                                      paketProvider.packages[index],
                                    );
                                  },
                                );
                              }

                              // 1-Column List on Smartphone
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: paketProvider.packages.length,
                                itemBuilder: (context, index) {
                                  return _buildPackageCard(
                                    context,
                                    paketProvider.packages[index],
                                  );
                                },
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 0.8),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, PaketPekerjaan pkg) {
    return IosCard(
      margin: const EdgeInsets.only(bottom: 14),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => PackageDetailScreen(packageId: pkg.packageId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Badge & Sync Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                isSynced: true,
                customLabel: pkg.bidang.toUpperCase(),
                customColor: AppColors.primary,
                customBgColor: AppColors.primaryLight,
              ),
              // StatusBadge(isSynced: pkg.isSynced),
            ],
          ),
          const SizedBox(height: 10),

          // Package Code & Title
          Text(
            pkg.packageId,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pkg.packageName,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Location & Budget Row
          Row(
            children: [
              const Icon(CupertinoIcons.location_solid, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pkg.lokasi,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.formatShort(pkg.nilaiKontrak),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Fisik',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${pkg.progresFisikSaatIni.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: pkg.progresFisikSaatIni >= 50 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pkg.progresFisikSaatIni / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E5EA),
              valueColor: AlwaysStoppedAnimation<Color>(
                pkg.progresFisikSaatIni >= 50 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => InputProgresScreen(package: pkg),
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.plus_circle_fill, size: 16),
                  label: Text('Input Progres', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => PackageDetailScreen(packageId: pkg.packageId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F2F7),
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('Detail', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(CupertinoIcons.search_circle_fill, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Paket Pekerjaan Tidak Ditemukan',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau filter bidang.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
