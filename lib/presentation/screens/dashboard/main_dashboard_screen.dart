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
import '../detail/package_detail_screen.dart';
import '../input/input_progres_screen.dart';
import '../settings/settings_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['Semua', 'BINA MARGA', 'Jalan', 'Jembatan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<PaketProvider>(context, listen: false).loadPackages();
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

                // API Active Server Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: authProvider.isProductionEnv ? AppColors.successBg : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (authProvider.isProductionEnv ? AppColors.success : AppColors.warning).withAlpha(77),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: authProvider.isProductionEnv ? AppColors.success : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        authProvider.isProductionEnv ? 'API Production' : 'API Dev',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: authProvider.isProductionEnv ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

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
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Alert Banner if API failed
                if (paketProvider.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            paketProvider.errorMessage!,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                          ),
                        ),
                        TextButton(
                          onPressed: () => paketProvider.loadPackages(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ],

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

                // Summary Metrics Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Total Paket PU',
                            value: '${paketProvider.totalPackages}',
                            subtitle: 'Terhubung ke Server API',
                            icon: CupertinoIcons.doc_text_fill,
                            iconColor: AppColors.primary,
                            bgColor: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Rata-rata Progres',
                            value: '${paketProvider.averageProgress.toStringAsFixed(1)}%',
                            subtitle: 'Fisik Lapangan',
                            icon: CupertinoIcons.chart_bar_fill,
                            iconColor: AppColors.success,
                            bgColor: AppColors.successBg,
                          ),
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
                      hintText: 'Cari nama paket, rekanan, atau lokasi...',
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

                // Package List Section Title & Limit Spinner Filter
                Row(
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
                        // Spinner Dropdown Filter Item for Limit
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
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
                              icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: AppColors.textSecondary),
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
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(CupertinoIcons.refresh_thin, color: AppColors.primary, size: 20),
                          onPressed: () => paketProvider.loadPackages(),
                          tooltip: 'Refresh',
                        ),
                      ],
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
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
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
    );
  }

  Widget _buildPackageCard(BuildContext context, PaketPekerjaan pkg) {
    return IosCard(
      margin: const EdgeInsets.only(bottom: 14),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => PackageDetailScreen(packageIdInt: pkg.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Bidang Badge & Tahun
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                isSynced: true,
                customLabel: pkg.bidang.toUpperCase(),
                customColor: AppColors.primary,
                customBgColor: AppColors.primaryLight,
              ),
              if (pkg.tahunAnggaran.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(6),
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

          // Package Title & Rekanan
          Text(
            pkg.namaPaket,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (pkg.rekanan.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Rekanan: ${pkg.rekanan}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Value & Location Row
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar_circle_fill, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                CurrencyFormatter.formatShort(pkg.nilaiKontrak),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(CupertinoIcons.location_solid, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                pkg.lokasi ?? '-',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
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
                      builder: (_) => PackageDetailScreen(packageIdInt: pkg.id),
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
