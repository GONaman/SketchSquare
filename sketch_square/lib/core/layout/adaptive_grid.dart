import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Responsive grid for drawing cards: as many columns as fit
/// [minTileWidth] (but at least [minColumns], at most [maxColumns]), so it
/// is 2 columns on phones, 3 on tablets and 4 on desktop. The column count is
/// computed from the sliver's real width, so rails and framed content are
/// accounted for.
class AdaptiveGridDelegate extends SliverGridDelegate {
  const AdaptiveGridDelegate({
    this.minTileWidth = 230,
    this.minColumns = 2,
    this.maxColumns = 4,
    this.mainAxisExtent,
    this.aspectRatio,
    this.spacing = 14,
  }) : assert(mainAxisExtent != null || aspectRatio != null);

  final double minTileWidth;
  final int minColumns;
  final int maxColumns;

  /// Fixed tile height. Wins over [aspectRatio] when both are given.
  final double? mainAxisExtent;

  /// Tile width / height.
  final double? aspectRatio;
  final double spacing;

  int columnsFor(double width) {
    final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
    return math.max(minColumns, math.min(maxColumns, fit));
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columnsFor(constraints.crossAxisExtent),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      mainAxisExtent: mainAxisExtent,
      childAspectRatio: aspectRatio ?? 1,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(AdaptiveGridDelegate old) =>
      old.minTileWidth != minTileWidth ||
      old.minColumns != minColumns ||
      old.maxColumns != maxColumns ||
      old.mainAxisExtent != mainAxisExtent ||
      old.aspectRatio != aspectRatio ||
      old.spacing != spacing;
}
