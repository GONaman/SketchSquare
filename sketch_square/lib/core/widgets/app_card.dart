import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'tap_scale.dart';

enum AppCardStyle {
  /// White surface, hairline border, soft shadow (default).
  elevated,

  /// Hairline border only; use for dense lists.
  outlined,

  /// Muted fill, no border; use for grouped info inside another card.
  tonal,
}

/// The standard surface. Rounded, hairline-bordered, softly shadowed, with
/// ripple + press-scale feedback when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.style = AppCardStyle.elevated,
    this.radius,
    this.clip = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final AppCardStyle style;
  final BorderRadius? radius;
  final bool clip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = radius ?? AppRadius.cardRadius;
    final tonal = style == AppCardStyle.tonal;
    final decoration = BoxDecoration(
      color:
          tonal ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      borderRadius: r,
      border: tonal ? null : Border.all(color: scheme.outlineVariant),
      boxShadow:
          style == AppCardStyle.elevated
              ? AppElevation.level1(scheme.brightness)
              : null,
    );
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: r, child: content),
      );
    }
    Widget card = DecoratedBox(
      decoration: decoration,
      child: clip ? ClipRRect(borderRadius: r, child: content) : content,
    );
    if (onTap != null) card = TapScale(child: card);
    if (semanticLabel != null) {
      card = Semantics(container: true, label: semanticLabel, child: card);
    }
    return card;
  }
}
