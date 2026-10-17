import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.blueprintBlue,
      onPrimary: Colors.white,
      secondary: AppColors.blueprintBlue,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightMutedText,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurface,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutline,
    ),
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blueprintBlueLight,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.blueprintBlueLight,
      onSecondary: AppColors.darkBackground,
      error: AppColors.errorDark,
      onError: AppColors.darkBackground,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkMutedText,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutline,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: scheme.onSurface),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }

  /// Inter via google_fonts, downloaded and cached on first use. If the
  /// download fails (offline) google_fonts logs and Flutter falls back to the
  /// platform default font. Tests set this to false to skip the network.
  static bool useGoogleFonts = true;

  static TextTheme _textTheme(TextTheme base) =>
      useGoogleFonts ? GoogleFonts.interTextTheme(base) : base;
}
