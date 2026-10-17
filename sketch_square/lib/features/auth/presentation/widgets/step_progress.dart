import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

/// Two-or-more step progress for the sign-up wizard. [current] is 0-based;
/// finished steps show a check. The connector fills as steps complete.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Step ${current + 1} of ${labels.length}: ${labels[current]}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Leave room for circles and a minimum connector so labels
          // ellipsise instead of overflowing on narrow screens / large text.
          final n = labels.length;
          final reserved = n * 36.0 + (n - 1) * (AppSpacing.sm * 2 + 24);
          final maxLabel = ((constraints.maxWidth - reserved) / n).clamp(
            24.0,
            double.infinity,
          );
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: _Connector(filled: i <= current, scheme: scheme),
                    ),
                  ),
                _Step(
                  index: i,
                  label: labels[i],
                  current: current,
                  maxLabelWidth: maxLabel,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.filled, required this.scheme});

  final bool filled;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: AppMotion.curve,
      height: 3,
      decoration: BoxDecoration(
        color: filled ? scheme.primary : scheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.current,
    required this.maxLabelWidth,
  });

  final double maxLabelWidth;
  final int index;
  final String label;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = index < current;
    final active = index == current;
    final filled = done || active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? scheme.primary : scheme.outline,
              width: 1.5,
            ),
          ),
          child:
              done
                  ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
                  : Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          active ? scheme.onPrimary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxLabelWidth),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: filled ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
