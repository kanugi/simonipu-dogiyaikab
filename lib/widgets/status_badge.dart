import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isSynced;
  final String? customLabel;
  final Color? customColor;
  final Color? customBgColor;

  const StatusBadge({
    super.key,
    required this.isSynced,
    this.customLabel,
    this.customColor,
    this.customBgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (customLabel != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: customBgColor ?? AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          customLabel!,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: customColor ?? AppColors.primary,
          ),
        ),
      );
    }

    final label = isSynced ? 'Tersinkron' : 'Antrean Sync (Lokal)';
    final color = isSynced ? AppColors.success : AppColors.warning;
    final bgColor = isSynced ? AppColors.successBg : AppColors.warningBg;
    final icon = isSynced ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.clock_fill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
