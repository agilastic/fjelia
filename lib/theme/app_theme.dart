import 'package:flutter/material.dart';

import 'fjelia_style.dart';

/// The app's palette. Surfaces and text follow DarkFjelia or LightFjelia;
/// the signal colours are the same in both.
abstract final class AppColors {
  static Color get background => duo(0xFF111111, 0xFFF2F4F7);
  static Color get surface => duo(0xFF1E1E1E, 0xFFFFFFFF);
  static Color get surfaceVariant => duo(0xFF2A2A2A, 0xFFEEF1F5);
  static Color get surfaceHighlight => duo(0xFF333333, 0xFFE3E7EC);

  static const green = Color(0xFF00D4A0);
  static const yellow = Color(0xFFFFCC00);
  static const red = Color(0xFFFF4444);
  static const blue = Color(0xFF4FC3F7);
  static const orange = Color(0xFFFF8C00);

  static Color get textPrimary => duo(0xFFFFFFFF, 0xFF15171A);
  static Color get textSecondary => duo(0xFF9E9E9E, 0xFF6B7280);
  static Color get textTertiary => duo(0xFF616161, 0xFF9AA0A8);

  static Color get chartGrid => duo(0xFF2A2A2A, 0xFFE3E7EC);
}

abstract class AppTheme {
  /// DarkFjelia.
  static ThemeData dark() => _build(FjeliaStyle.dark);

  /// LightFjelia.
  static ThemeData light() => _build(FjeliaStyle.light);

  static ThemeData _build(FjeliaStyle style) {
    final before = Fjelia.style;
    Fjelia.style = style;
    try {
      return _theme(style == FjeliaStyle.light);
    } finally {
      Fjelia.style = before;
    }
  }

  static ThemeData _theme(bool light) {
    final muted = duo(0xFFCCCCCC, 0xFF4B5563);
    return ThemeData(
      useMaterial3: true,
      brightness: light ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: (light ? ColorScheme.light : ColorScheme.dark)(
        primary: AppColors.blue,
        onPrimary: Colors.black,
        secondary: AppColors.green,
        onSecondary: Colors.black,
        error: AppColors.red,
        onError: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.green,
        secondarySelectedColor: AppColors.green,
        showCheckmark: false,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          color: Colors.black,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        labelStyle: TextStyle(color: muted, fontSize: 11),
        suffixStyle: TextStyle(color: muted, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green.withValues(alpha: .3)
              : AppColors.surfaceVariant,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.green,
        labelColor: AppColors.textPrimary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
        unselectedLabelColor: muted,
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 72,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: muted, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        labelLarge: TextStyle(
          color: muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
