import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Label on the left, tabular value on the right: price summaries, receipts.
/// [emphasis] renders the row as a total.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
    this.valueKey,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Key? valueKey;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle =
        emphasis
            ? theme.textTheme.titleMedium
            : theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            );
    final valueStyle =
        (emphasis
                ? theme.textTheme.titleLarge
                : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ))
            ?.copyWith(color: valueColor)
            .tabular;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: labelStyle)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              style: valueStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
