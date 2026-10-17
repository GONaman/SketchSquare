import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/password_strength.dart';

/// Four-segment strength bar with a text label and one actionable hint.
/// Rebuilds from [controller], so it can sit anywhere under the field.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final level = PasswordStrength.evaluate(value.text);
        return AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child:
              level == PasswordStrengthLevel.empty
                  ? const SizedBox(width: double.infinity)
                  : _Meter(level: level),
        );
      },
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.level});

  final PasswordStrengthLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sem = AppSemanticColors.of(context);
    final filled = level.index; // weak=1 … strong=4
    final color = switch (level) {
      PasswordStrengthLevel.weak => scheme.error,
      PasswordStrengthLevel.fair => sem.warning,
      PasswordStrengthLevel.good => scheme.primary,
      _ => sem.success,
    };
    final label = PasswordStrength.label(level);
    final hint = switch (level) {
      PasswordStrengthLevel.weak =>
        'Use at least ${PasswordStrength.minLength} characters.',
      PasswordStrengthLevel.fair => 'Add numbers, capitals or symbols.',
      PasswordStrengthLevel.good => 'A longer password is even safer.',
      _ => 'Nice and strong.',
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        label: 'Password strength: $label',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.curve,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < filled ? color : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  $hint',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
