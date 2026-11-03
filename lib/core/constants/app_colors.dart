import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Colors: Biru Dinas PU ──────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0); // Royal Ocean Blue
  static const Color primaryDark = Color(0xFF0D47A1); // Deep Navy Blue
  static const Color primaryLight = Color(0xFFE3F2FD); // Soft Blue Tint

  // ── Secondary Colors: Ungu SIMONI Web ──────────────────────────────────────
  static const Color secondary = Color(0xFF4A148C); // Deep Royal Purple
  static const Color secondaryMedium = Color(0xFF5E35B1); // Indigo Purple
  static const Color secondaryLight = Color(0xFFEDE7F6); // Soft Purple Tint

  // ── Accent Colors: Orange Khas Web & Lapangan PU ───────────────────────────
  static const Color accent = Color(0xFFF57C00); // Vibrant PU Orange
  static const Color accentDark = Color(0xFFE65100); // Deep Orange
  static const Color accentLight = Color(0xFFFFF3E0); // Soft Orange Tint
  static const Color goldPU = Color(0xFFFFB300); // Kuning Keemasan Logo PU

  // ── Backgrounds & Canvas (Material 3 Crisp Surfaces) ──────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate Canvas Light
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure White Surface
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Tonal Surface

  // ── Text Colors (Slate Neutral) ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (High Contrast)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (Readable Body)
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 (Subtle)
  static const Color textOnPrimary = Colors.white;

  // ── Status & Notification Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successBg = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color warningBg = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFEF4444); // Modern Red
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color error = danger;
  static const Color errorBg = dangerBg;

  static const Color info = Color(0xFF0284C7); // Sky Blue
  static const Color infoBg = Color(0xFFF0F9FF);

  // ── Material 3 Borders & Elevation Shadows ─────────────────────────────────
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderMedium = Color(0xFFCBD5E1); // Slate 300
  static const Color shadowColor = Color(0x0C0F172A); // Soft Slate Shadow
  static const Color shadowElevated = Color(0x180F172A);

  // ── Glassmorphism (Optional Overlays) ──────────────────────────────────────
  static const Color glassWhite = Color(0xDDFFFFFF);
  static const Color glassBorder = Color(0x40E2E8F0);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Header melengkung utama (Gradasi Biru Dinas PU ke Ungu SIMONI Web)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradasi tombol aksen (Orange PU)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Gradasi kartu metrik biru
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
