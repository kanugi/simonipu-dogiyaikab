import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Tombol standar Material 3 untuk Aplikasi SIMONI PU
class SimoniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final bool isAccent;
  final bool isDanger;
  final double height;
  final double? width;
  final Gradient? gradient;

  const SimoniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.isAccent = false,
    this.isDanger = false,
    this.height = 50,
    this.width,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primary;
    Color fg = Colors.white;

    if (isAccent) {
      bg = AppColors.accent;
      fg = Colors.white;
    } else if (isSecondary) {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else if (isDanger) {
      bg = AppColors.danger;
      fg = Colors.white;
    }

    final buttonWidget = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: gradient != null ? Colors.transparent : bg,
        foregroundColor: fg,
        shadowColor: gradient != null ? Colors.transparent : AppColors.shadowColor,
        elevation: gradient != null ? 0 : 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
    );

    if (gradient != null) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: buttonWidget,
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height,
        ),
        child: buttonWidget,
      ),
    );
  }
}

/// Backward-compatibility alias
typedef IosButton = SimoniButton;