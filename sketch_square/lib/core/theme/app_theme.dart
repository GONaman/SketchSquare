import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  /// Inter + Space Grotesk via google_fonts (cached after first download,
  /// platform fallback offline). Tests set this to false to skip the network.
  static bool get useGoogleFonts => AppTypography.useGoogleFonts;
  static set useGoogleFonts(bool v) => AppTypography.useGoogleFonts = v;

  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.blueprintBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blueprintTint,
      onPrimaryContainer: AppColors.blueprintInk,
      secondary: AppColors.copper,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.copperTint,
      onSecondaryContainer: Color(0xFF6B2F0B),
      tertiary: AppColors.emerald,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.emeraldTint,
      onTertiaryContainer: Color(0xFF0B3D27),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorTint,
      onErrorContainer: Color(0xFF601410),
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightMutedText,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurface,
      surfaceContainerHigh: AppColors.lightSurfaceMuted,
      surfaceContainerHighest: AppColors.lightSurfaceStrong,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineSoft,
      inverseSurface: AppColors.blueprintInk,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.blueprintBlueLight,
      shadow: Color(0xFF0B1E52),
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    ),
    AppSemanticColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blueprintBlueLight,
      onPrimary: AppColors.darkBackground,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFDCE4FF),
      secondary: AppColors.copperLight,
      onSecondary: AppColors.darkBackground,
      secondaryContainer: AppColors.copperDarkTint,
      onSecondaryContainer: Color(0xFFFFDCC6),
      tertiary: AppColors.emeraldLight,
      onTertiary: AppColors.darkBackground,
      tertiaryContainer: AppColors.emeraldDarkTint,
      onTertiaryContainer: Color(0xFFCFF3E0),
      error: AppColors.errorDark,
      onError: AppColors.darkBackground,
      errorContainer: AppColors.errorDarkTint,
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkMutedText,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceMuted,
      surfaceContainerHighest: AppColors.darkSurfaceStrong,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineSoft,
      inverseSurface: AppColors.darkText,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.blueprintBlue,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    ),
    AppSemanticColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [semantic],
    );
    final text = AppTypography.textTheme(base.textTheme, scheme);
    final controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.controlRadius,
    );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    const buttonMin = Size(64, 52);
    const buttonPad = EdgeInsets.symmetric(horizontal: 22, vertical: 14);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: AppRadius.controlRadius,
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: text.headlineSmall,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: 0.18),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.onSurface,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected)
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected)
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outline),
        shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        secondaryLabelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary, 1.8),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.8),
        disabledBorder: border(scheme.outlineVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: pill,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color:
                s.contains(WidgetState.selected)
                    ? (isDark ? scheme.onPrimaryContainer : scheme.primary)
                    : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            fontWeight:
                s.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
            color:
                s.contains(WidgetState.selected)
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLowest,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 0,
        shape: controlShape,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleSmall?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        circularTrackColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
