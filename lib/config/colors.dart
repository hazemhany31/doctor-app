
import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية — Ultra-Premium Medical Theme
class AppColors {
  // === Primary Palette ===
  static const Color primaryBlue = Color(0xFF0B6E6E); // Deep teal (legacy alias)
  static const Color primary = Color(0xFF0B6E6E); // Deep teal
  static const Color primaryLight = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF064E4E);
  static const Color secondaryTeal = Color(0xFF0D9488);

  // === Accent / Gold ===
  static const Color accent = Color(0xFFF59E0B);     // Warm gold
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentGold = Color(0xFFD4A017);  // Rich gold
  static const Color accentGoldLight = Color(0xFFFFD700);

  // === Header / Hero ===
  static const Color headerDark = Color(0xFF0A0F1E);  // Deep navy-black
  static const Color headerMid  = Color(0xFF0B6E6E);  // Teal

  // === Status Colors ===
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // === Background Colors ===
  static const Color background       = Color(0xFFF8FAFC);
  static const Color cardBackground   = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF0F4F8);
  static const Color surfaceVariant   = Color(0xFFE2E8F0);

  // === Glass / Surface ===
  static const Color glassWhite  = Color(0xFAFFFFFF);  // near-opaque white
  static const Color glassTeal   = Color(0x1A0B6E6E);  // 10% teal
  static const Color glassDark   = Color(0x0F0A0F1E);  // 6% navy

  // === Text Colors ===
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint      = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark    = Color(0xFFE2E8F0);

  // === Border Colors ===
  static const Color border  = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);

  // === Status Chip Colors ===
  static const Color pendingColor   = Color(0xFFF59E0B);
  static const Color confirmedColor = Color(0xFF10B981);
  static const Color completedColor = Color(0xFF3B82F6);
  static const Color cancelledColor = Color(0xFFEF4444);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A0F1E), Color(0xFF0B6E6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0A0F1E), Color(0xFF0D4444)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Premium header: deep navy → teal with subtle gold tone
  static const LinearGradient premiumHeaderGradient = LinearGradient(
    colors: [Color(0xFF060D1A), Color(0xFF0B3D3D), Color(0xFF0B6E6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0B6E6E), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFFFD700), Color(0xFFD4A017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Shadows ===
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0B6E6E).withValues(alpha: 0.10),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get premiumCardShadow => [
    BoxShadow(
      color: const Color(0xFF0B6E6E).withValues(alpha: 0.18),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get goldShadow => [
    BoxShadow(
      color: const Color(0xFFD4A017).withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0xFF0B6E6E).withValues(alpha: 0.18),
      blurRadius: 32,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
}
