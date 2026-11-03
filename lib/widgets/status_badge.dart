import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isSynced;
  final String? customLabel;
  final Color? customColor;
  final Color? customBgColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.isSynced,
    this.customLabel,
    this.customColor,
    this.customBgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (customLabel != null) {
      final color = customColor ?? AppColors.primary;
      final bgColor = customBgColor ?? AppColors.primaryLight;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(40), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              customLabel!,
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

    final label = isSynced ? 'Tersinkron' : 'Antrean Sync (Lokal)';
    final color = isSynced ? AppColors.success : AppColors.warning;
    final bgColor = isSynced ? AppColors.successBg : AppColors.warningBg;
    final badgeIcon = icon ?? (isSynced ? Icons.check_circle_rounded : Icons.schedule_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 13, color: color),
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

