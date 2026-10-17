import 'package:flutter/material.dart';

/// Brand palette — "blueprint / studio": warm drafting-paper neutrals, deep
/// blueprint blue as the primary, a copper "pencil" accent for highlights and
/// green for free/positive. Screens must read colours from
/// `Theme.of(context).colorScheme` (or [AppSemanticColors]); only this file and
/// `app_theme.dart` may reference raw values.
abstract final class AppColors {
  // Brand
  static const blueprintBlue = Color(0xFF1F3A93);
  // Lighter tint of the primary so it keeps contrast on dark surfaces.
  static const blueprintBlueLight = Color(0xFF9DB1F5);
  static const blueprintInk = Color(0xFF0B1E52);
  static const blueprintTint = Color(0xFFE6ECFB);
  static const copper = Color(0xFFB5541B);
  static const copperTint = Color(0xFFFBE8DA);
  static const copperLight = Color(0xFFF2AA7B);
  static const copperDarkTint = Color(0xFF4A2410);
  static const emerald = Color(0xFF16714A);
  static const emeraldTint = Color(0xFFDAF1E5);
  static const emeraldLight = Color(0xFF74D4A4);
  static const emeraldDarkTint = Color(0xFF123B2B);
  static const amber = Color(0xFFB7791F);
  static const amberTint = Color(0xFFFCEFD2);
  static const amberLight = Color(0xFFF3C969);
  static const amberDarkTint = Color(0xFF45340F);

  // Light neutrals (warm paper)
  static const lightBackground = Color(0xFFF6F5F1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceMuted = Color(0xFFEFEDE7);
  static const lightSurfaceStrong = Color(0xFFE6E3DB);
  static const lightText = Color(0xFF0F1729);
  static const lightMutedText = Color(0xFF555F73);
  static const lightOutline = Color(0xFFDAD7CE);
  static const lightOutlineSoft = Color(0xFFE9E7E0);

  // Dark neutrals (blue-black ink)
  static const darkBackground = Color(0xFF0B0F17);
  static const darkSurface = Color(0xFF131925);
  static const darkSurfaceMuted = Color(0xFF1A2231);
  static const darkSurfaceStrong = Color(0xFF232D40);
  static const darkText = Color(0xFFF0F2F7);
  static const darkMutedText = Color(0xFF9EA8BB);
  static const darkOutline = Color(0xFF2B3548);
  static const darkOutlineSoft = Color(0xFF1F2839);
  static const darkPrimaryContainer = Color(0xFF1B2A62);

  static const error = Color(0xFFB3261E);
  static const errorTint = Color(0xFFFBE4E1);
  static const errorDark = Color(0xFFF2B8B5);
  static const errorDarkTint = Color(0xFF4A1A17);
}

/// Colours that have no Material 3 slot (success / warning tones, the copper
/// accent, the ink hero colour). Read with `AppSemanticColors.of(context)`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.blueprintGrid,
    required this.ink,
    required this.onInk,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  /// Warm copper accent ("pencil"): highlights and hero price chips.
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;

  /// Line colour for blueprint grid motifs.
  final Color blueprintGrid;

  /// Deep navy used for hero/inverse surfaces (identical in both modes).
  final Color ink;
  final Color onInk;

  static const light = AppSemanticColors(
    success: AppColors.emerald,
    onSuccess: Colors.white,
    successContainer: AppColors.emeraldTint,
    warning: AppColors.amber,
    onWarning: Colors.white,
    warningContainer: AppColors.amberTint,
    accent: AppColors.copper,
    onAccent: Colors.white,
    accentContainer: AppColors.copperTint,
    onAccentContainer: Color(0xFF6B2F0B),
    blueprintGrid: AppColors.blueprintBlue,
    ink: AppColors.blueprintInk,
    onInk: Colors.white,
  );

  static const dark = AppSemanticColors(
    success: AppColors.emeraldLight,
    onSuccess: AppColors.darkBackground,
    successContainer: AppColors.emeraldDarkTint,
    warning: AppColors.amberLight,
    onWarning: AppColors.darkBackground,
    warningContainer: AppColors.amberDarkTint,
    accent: AppColors.copperLight,
    onAccent: AppColors.darkBackground,
    accentContainer: AppColors.copperDarkTint,
    onAccentContainer: Color(0xFFFFDCC6),
    blueprintGrid: AppColors.blueprintBlueLight,
    ink: AppColors.blueprintInk,
    onInk: Colors.white,
  );

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? blueprintGrid,
    Color? ink,
    Color? onInk,
  }) => AppSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentContainer: accentContainer ?? this.accentContainer,
    onAccentContainer: onAccentContainer ?? this.onAccentContainer,
    blueprintGrid: blueprintGrid ?? this.blueprintGrid,
    ink: ink ?? this.ink,
    onInk: onInk ?? this.onInk,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccentContainer: l(onAccentContainer, other.onAccentContainer),
      blueprintGrid: l(blueprintGrid, other.blueprintGrid),
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
    );
  }
}
