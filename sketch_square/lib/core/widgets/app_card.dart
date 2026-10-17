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
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.radius ?? AppRadius.cardRadius;
    final tonal = widget.style == AppCardStyle.tonal;
    final interactive = widget.onTap != null;
    // Pointer and keyboard affordances; both are no-ops on touch.
    final lifted = interactive && _hovered;
    final decoration = BoxDecoration(
      color:
          tonal ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      borderRadius: r,
      border:
          _focused
              ? Border.all(color: scheme.primary, width: 2)
              : tonal
              ? null
              : Border.all(
                color: lifted ? scheme.outline : scheme.outlineVariant,
              ),
      boxShadow:
          lifted
              ? AppElevation.level2(scheme.brightness)
              : widget.style == AppCardStyle.elevated
              ? AppElevation.level1(scheme.brightness)
              : null,
    );
    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (interactive) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: r,
          onHover: (v) => setState(() => _hovered = v),
          onFocusChange: (v) => setState(() => _focused = v),
          child: content,
        ),
      );
    }
    Widget card = DecoratedBox(
      decoration: decoration,
      child: widget.clip ? ClipRRect(borderRadius: r, child: content) : content,
    );
    if (interactive) card = TapScale(child: card);
    if (widget.semanticLabel != null) {
      card = Semantics(
        container: true,
        label: widget.semanticLabel,
        child: card,
      );
    }
    return card;
  }
}
