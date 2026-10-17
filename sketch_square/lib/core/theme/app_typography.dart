import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale. Inter for UI/body, Space Grotesk for display & titles (a
/// technical, drafting-lettering feel). Both come from google_fonts; when the
/// download fails (offline) the platform font is used.
abstract final class AppTypography {
  /// Tests set this to false to skip network font fetches.
  static bool useGoogleFonts = true;

  static TextTheme textTheme(TextTheme base, ColorScheme scheme) {
    final body = useGoogleFonts ? GoogleFonts.interTextTheme(base) : base;
    TextStyle display(TextStyle? fallback, TextStyle s) =>
        useGoogleFonts
            ? GoogleFonts.spaceGrotesk(textStyle: s)
            : (fallback ?? const TextStyle()).merge(s);

    final t = body.copyWith(
      displayLarge: display(
        body.displayLarge,
        const TextStyle(
          fontSize: 44,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
      ),
      displayMedium: display(
        body.displayMedium,
        const TextStyle(
          fontSize: 36,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      displaySmall: display(
        body.displaySmall,
        const TextStyle(
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
      ),
      headlineMedium: display(
        body.headlineMedium,
        const TextStyle(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      headlineSmall: display(
        body.headlineSmall,
        const TextStyle(
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      titleLarge: display(
        body.titleLarge,
        const TextStyle(
          fontSize: 19,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
    return t.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}

extension AppTextStyleX on TextStyle {
  /// Fixed-width digits so prices and dimensions line up in lists/tables.
  TextStyle get tabular => copyWith(
    fontFeatures: [...?fontFeatures, const FontFeature.tabularFigures()],
  );
}
