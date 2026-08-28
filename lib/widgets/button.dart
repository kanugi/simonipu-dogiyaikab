import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class IosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final bool isDanger;
  final double height;
  final double? width;

  const IosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDanger = false,
    this.height = 50,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primary;
    Color fg = Colors.white;

    if (isSecondary) {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else if (isDanger) {
      bg = const Color.fromARGB(255, 255, 38, 26);
      fg = Colors.white;
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
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
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],

                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}