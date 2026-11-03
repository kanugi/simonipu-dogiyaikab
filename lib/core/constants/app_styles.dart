import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // ── Border Radius Tokens ──────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 18.0;
  static const double radiusXLarge = 24.0;
  static const double radiusHeader = 28.0; // Lengkungan Curved Header

  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusLarge);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radiusMedium);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(100.0);
  static const BorderRadius headerBorderRadius = BorderRadius.vertical(
    bottom: Radius.circular(radiusHeader),
  );

  // ── Material 3 Soft Elevation Shadows ──────────────────────────────────────
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppColors.shadowColor,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withAlpha(8),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.shadowColor,
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  /// Floating shadow khusus untuk Floating Search Card & Navigation Dock
  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: const Color(0x1A0F172A),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0x0A0F172A),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Text Styles (Outfit untuk Judul & Inter untuk Body) ─────────────────────
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle titleSmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle chipText(BuildContext context, {bool isSelected = false}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      );
}
