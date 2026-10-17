import 'package:flutter/material.dart';

/// Brand palette: off-white / near-black with a single blueprint-blue accent.
abstract final class AppColors {
  static const blueprintBlue = Color(0xFF1F3A93);
  // Lighter tint of the accent so it keeps contrast on dark surfaces.
  static const blueprintBlueLight = Color(0xFF9DB1F5);

  static const lightBackground = Color(0xFFFAF9F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111418);
  static const lightMutedText = Color(0xFF5B6270);
  static const lightOutline = Color(0xFFDAD8D2);

  static const darkBackground = Color(0xFF0E1116);
  static const darkSurface = Color(0xFF171B22);
  static const darkText = Color(0xFFF2F1ED);
  static const darkMutedText = Color(0xFFA3A9B5);
  static const darkOutline = Color(0xFF2B313B);

  static const error = Color(0xFFB3261E);
  static const errorDark = Color(0xFFF2B8B5);
}
