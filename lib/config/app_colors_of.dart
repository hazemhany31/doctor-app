
import 'package:flutter/material.dart';
import 'colors.dart';

/// Context-aware palette — automatically selects light or dark variant.
///
/// Usage:
///   final c = AppColors.of(context);  // or AppColorsOf(context)
///   Container(color: c.scaffoldBg)
class AppColorsOf {
  final bool isDark;

  AppColorsOf(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  // ── Backgrounds ──────────────────────────────────────────────────────
  Color get scaffoldBg =>
      isDark ? AppColors.darkScaffold : AppColors.scaffoldBackground;

  Color get cardBg =>
      isDark ? AppColors.darkCard : AppColors.cardBackground;

  Color get surfaceBg =>
      isDark ? AppColors.darkSurface : AppColors.surfaceVariant;

  Color get navBarBg =>
      isDark ? AppColors.darkNavBar : Colors.white;

  // ── Text ──────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get textHint =>
      isDark ? AppColors.darkTextHint : AppColors.textHint;

  // ── Borders & Dividers ───────────────────────────────────────────────
  Color get border =>
      isDark ? AppColors.darkBorder : AppColors.border;

  Color get divider =>
      isDark ? AppColors.darkDivider : AppColors.divider;

  // ── Glass / tinted surfaces ──────────────────────────────────────────
  Color get glassTeal =>
      isDark ? AppColors.darkGlassTeal : AppColors.glassTeal;

  // ── Shadows (lighter in dark mode) ──────────────────────────────────
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]
      : AppColors.cardShadow;

  List<BoxShadow> get floatingShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ]
      : AppColors.floatingShadow;
}
