import 'package:flutter/material.dart';

/// 4-pt spacing scale. Prefer these over literals.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Horizontal page gutter on phones.
  static const double gutter = 20;
}

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get cardRadius => BorderRadius.circular(lg);
  static BorderRadius get controlRadius => BorderRadius.circular(md);
  static BorderRadius get chipRadius => BorderRadius.circular(sm);
}

/// Soft, layered shadows (blue-tinted in light mode so they feel like
/// blueprint paper, near-invisible in dark mode where borders carry depth).
abstract final class AppElevation {
  static List<BoxShadow> level1(Brightness b) =>
      b == Brightness.dark
          ? const []
          : const [
            BoxShadow(
              color: Color(0x0F0B1E52),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x0A0B1E52),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ];

  static List<BoxShadow> level2(Brightness b) =>
      b == Brightness.dark
          ? const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ]
          : const [
            BoxShadow(
              color: Color(0x140B1E52),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x140B1E52),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}
