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
  final List<String> _categories = [
    'Semua',
    'BINA MARGA',
    'CIPTA KARYA',
    'SUMBER DAYA AIR',
    'PERUMAHAN',
    'Jalan',
    'Jembatan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<PaketProvider>(context, listen: false).loadPackages();
        final syncProv = Provider.of<SyncProvider>(context, listen: false);
        if (syncProv.queueCount > 0 && !syncProv.isSyncing) {
          syncProv.performBiDirectionalSync();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paketProvider = Provider.of<PaketProvider>(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final syncProv = Provider.of<SyncProvider>(context, listen: false);
          final futures = <Future>[
            paketProvider.loadPackages(),
          ];
          if (syncProv.queueCount > 0 && !syncProv.isSyncing) {
            futures.add(syncProv.performBiDirectionalSync());
          }
          await Future.wait(futures);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Curved Header (Gradasi Biru Dinas PU ke Ungu SIMONI) ────
              _buildCurvedHeader(context, authProvider),

              // ── 2. Floating Overlapping Search Bar ──────────────────────────
              _buildFloatingSearchBar(paketProvider),

              // ── Content Body (Padding) ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Bidang Chips (Kapsul Horisontal)
                    _buildCategoryChips(paketProvider),
                    const SizedBox(height: 16),

                    // Highlight / Sync Alert Banner (jika ada data antrean)
                    Consumer<SyncProvider>(
                      builder: (context, syncProv, _) {
                        if (syncProv.queueCount > 0) {
                          return _buildSyncAlertBanner(context, syncProv.queueCount);
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Error Alert Banner (jika koneksi gagal)
                    if (paketProvider.errorMessage != null) ...[
                      _buildErrorBanner(paketProvider),
                      const SizedBox(height: 16),
                    ],

                    // Summary Metric Cards (Total Paket & Rata-rata Progres)
                    _buildSummaryMetrics(context, paketProvider),
                    const SizedBox(height: 22),

                    // Package List Header (Title + Limit Filter + Refresh)
                    _buildListHeader(context, paketProvider),
                    const SizedBox(height: 12),

                    // Adaptive Package Cards Grid / List
                    paketProvider.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        : paketProvider.packages.isEmpty
                            ? _buildEmptyState()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  if (isTablet) {
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.35,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS SECTION ────────────────────────────────────────────────────────

  /// 1. Curved Header dengan Gradasi Biru-Ungu Elegan
  Widget _buildCurvedHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: AppStyles.headerBorderRadius,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 42, // Extra space to accommodate overlapping search bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Row: User Avatar, Name, Environment & Action Icons
          Row(
            children: [
              // User Avatar with Ring
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(40),
                  border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),

              // User Info & Agency
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${authProvider.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Dinas PUPR Dogiyai • ${DateFormatter.formatDateOnly(DateTime.now())}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),

              // API Environment Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: authProvider.isProductionEnv ? AppColors.success : AppColors.goldPU,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      authProvider.isProductionEnv ? 'Prod' : 'Dev',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Sync Queue Icon Button with Counter Badge
              Consumer<SyncProvider>(
                builder: (context, syncProv, _) {
                  final count = syncProv.queueCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            count > 0 ? Icons.cloud_sync_rounded : Icons.cloud_done_rounded,
                            color: count > 0 ? AppColors.goldPU : Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Antrean Offline ($count)',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                            );
                          },
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: GoogleFonts.robotoMono(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),

              // Settings Icon Button
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Headline & Subtitle
          Text(
            'Simoni PU',
            style: AppStyles.headlineLarge(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistem Informasi Monitoring Pekerjaan Umum Kabupaten Dogiyai',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withAlpha(210),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Floating Overlapping Search Bar (Mengadopsi Gambar 1)
  Widget _buildFloatingSearchBar(PaketProvider paketProvider) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppStyles.floatingShadow,
          border: Border.all(color: AppColors.borderLight, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => paketProvider.searchPackages(val),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Cari nama paket, rekanan, atau bidang...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      paketProvider.searchPackages('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  /// 3. Filter Bidang Chips (Kapsul Horisontal)
  Widget _buildCategoryChips(PaketProvider paketProvider) {
    return SizedBox(
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
            labelStyle: AppStyles.chipText(context, isSelected: isSelected),
            elevation: isSelected ? 2 : 0,
            shadowColor: AppColors.primary.withAlpha(50),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: 0.8,
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
    );
  }

  /// 4. Highlight / Sync Alert Banner (Aksen Orange PU)
  Widget _buildSyncAlertBanner(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(80), width: 1),
        boxShadow: AppStyles.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ $count Data di Antrean Offline',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tersimpan di perangkat lokal. Ketuk untuk sinkronisasi.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Error Banner jika API Gagal
  Widget _buildErrorBanner(PaketProvider paketProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              paketProvider.errorMessage!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => paketProvider.loadPackages(),
            child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 5. Metric Summary Cards (Material 3 Dual Cards)
  Widget _buildSummaryMetrics(BuildContext context, PaketProvider paketProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Total Paket PU',
            value: '${paketProvider.totalPackages}',
            subtitle: 'Terhubung ke Server API',
            icon: Icons.folder_special_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Rata-rata Progres',
            value: '${paketProvider.averageProgress.toStringAsFixed(1)}%',
            subtitle: 'Realisasi Lapangan',
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.accent,
            iconBgColor: AppColors.accentLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return SimoniCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  /// 6. Package List Header Section
  Widget _buildListHeader(BuildContext context, PaketProvider paketProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Paket Pekerjaan (${paketProvider.packages.length})',
                style: AppStyles.titleMedium(context),
              ),
              const SizedBox(height: 2),
              Text(
                'Menampilkan ${paketProvider.packages.length} dari ${paketProvider.totalPackages} paket',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Dropdown Limit Selector
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: paketProvider.limitOptions.contains(paketProvider.limit)
                      ? paketProvider.limit
                      : paketProvider.limitOptions.first,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      paketProvider.setLimit(newValue);
                    }
                  },
                  items: paketProvider.limitOptions.map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value item'),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
              onPressed: () => paketProvider.loadPackages(),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ],
    );
  }

  /// 7. Package Card Item (Material 3 Card dengan Dual Progress & Action Buttons)
  Widget _buildPackageCard(BuildContext context, PaketPekerjaan pkg) {
    return SimoniCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PackageDetailScreen(
              packageIdInt: pkg.id,
              initialPackage: pkg,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Bidang Badge & Tahun Anggaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                isSynced: true,
                customLabel: pkg.bidang.toUpperCase(),
                customColor: AppColors.primary,
                customBgColor: AppColors.primaryLight,
                icon: Icons.category_rounded,
              ),
              if (pkg.tahunAnggaran.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight, width: 0.8),
                  ),
                  child: Text(
                    'TA ${pkg.tahunAnggaran}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Package Title
          Text(
            pkg.namaPaket,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Rekanan Contractor Info
          if (pkg.rekanan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    pkg.rekanan,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Value & Location Row
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                CurrencyFormatter.formatShort(pkg.nilaiKontrak),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                pkg.lokasi ?? 'Kab. Dogiyai',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Input Progres (Orange PU) & Detail (Tonal / Outlined)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InputProgresScreen(package: pkg),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 17),
                  label: Text(
                    'Input Progres',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PackageDetailScreen(
                        packageIdInt: pkg.id,
                        initialPackage: pkg,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: Text(
                  'Detail',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty State Display
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'Paket Pekerjaan Tidak Ditemukan',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ubah kata kunci pencarian atau pilih filter bidang lainnya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
