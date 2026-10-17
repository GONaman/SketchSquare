import 'package:flutter/material.dart';

import '../format/price.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Price in tabular figures with Indian grouping; `FREE` text for free items.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.paise,
    this.style,
    this.color,
    this.compact = false,
  });

  final int paise;
  final TextStyle? style;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    return Text(
      compact ? formatPaiseCompact(paise) : formatPaise(paise),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base?.copyWith(color: color).tabular,
    );
  }
}

/// Star + value ("★ 4.5") or a muted "New" when there are no ratings yet.
class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (count <= 0) {
      return Text(
        'New',
        style: theme.textTheme.labelMedium?.copyWith(color: muted),
      );
    }
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} from $count reviews',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: AppSemanticColors.of(context).warning,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.tabular,
          ),
        ],
      ),
    );
  }
}
