import 'package:flutter/widgets.dart';

/// Window-width classes (Material 3 style). Phones are [compact]; tablets and
/// small desktop windows [medium]; wide desktop/web windows [expanded].
enum ScreenSize {
  compact,
  medium,
  expanded;

  bool get isCompact => this == compact;
  bool get isMedium => this == medium;
  bool get isExpanded => this == expanded;

  /// Medium or wider: space for rails, side panels and multi-column layouts.
  bool get isWide => this != compact;
}

abstract final class Breakpoints {
  /// Widths below this are [ScreenSize.compact].
  static const double medium = 600;

  /// Widths above this are [ScreenSize.expanded] (1024 itself is medium).
  static const double expanded = 1024;

  /// Max content width for browse screens (feeds, detail, lists).
  static const double browseMaxWidth = 1200;

  /// Max content width for forms, auth, checkout, wallet and settings.
  static const double formMaxWidth = 560;

  static ScreenSize of(double width) {
    if (width < medium) return ScreenSize.compact;
    if (width <= expanded) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

extension ScreenSizeContext on BuildContext {
  /// Class of the full window width (use [Breakpoints.of] with a
  /// `LayoutBuilder` width when the width of a sub-area matters instead).
  ScreenSize get screenSize => Breakpoints.of(MediaQuery.sizeOf(this).width);

  bool get isCompact => screenSize.isCompact;
  bool get isWide => screenSize.isWide;
  bool get isExpanded => screenSize.isExpanded;
}
