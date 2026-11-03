import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

/// Kartu standar Material 3 untuk Aplikasi SIMONI PU
class SimoniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool isGlass;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final Border? border;
  final double? elevation;
  final List<BoxShadow>? customShadow;

  const SimoniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 12.0),
    this.onTap,
    this.isGlass = false,
    this.color,
    this.gradient,
    this.borderRadius = 18.0,
    this.border,
    this.elevation,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = BorderRadius.circular(borderRadius);
    
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (isGlass ? AppColors.glassWhite : AppColors.cardBackground))
            : null,
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        border: border ??
            Border.all(
              color: isGlass ? AppColors.glassBorder : AppColors.borderLight,
              width: 0.8,
            ),
        boxShadow: customShadow ?? AppStyles.cardShadow,
      ),
      child: child,
    );

    if (isGlass) {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveBorderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveBorderRadius,
            splashColor: AppColors.primary.withAlpha(20),
            highlightColor: AppColors.primary.withAlpha(10),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }
}

/// Backward-compatibility alias agar kode lama tetap jalan lancar dengan visual baru
typedef IosCard = SimoniCard;

