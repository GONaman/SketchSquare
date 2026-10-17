import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/money.dart';
import '../upload_flow_controller.dart';
import 'form_widgets.dart';

class PricingStep extends ConsumerWidget {
  const PricingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final f = s.form;
    final theme = Theme.of(context);
    final error = s.showErrors ? s.pricingErrors['price'] : null;
    final contribution = s.contribution;
    final blocked = contribution != null && !contribution.canPublishPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (contribution != null && contribution.ruleActive) ...[
          MessageBanner(
            key: const ValueKey('contribution-banner'),
            message: contribution.explanation,
            isError: false,
          ),
          const SizedBox(height: 8),
        ],
        SegmentedButton<bool>(
          key: const ValueKey('price-mode'),
          segments: [
            const ButtonSegment(value: true, label: Text('Free')),
            ButtonSegment(
              value: false,
              label: const Text('Paid'),
              enabled: !blocked,
            ),
          ],
          selected: {f.isFree},
          onSelectionChanged:
              (v) => c.updateForm((f) => f.copyWith(isFree: v.first)),
        ),
        const SizedBox(height: 16),
        if (s.paidBlockedByContribution)
          MessageBanner(
            key: const ValueKey('contribution-blocked'),
            message: contribution!.blockedMessage,
          ),
        if (f.isFree)
          Text(
            'Anyone can download this drawing for free. You will not earn from it.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          FormTextField(
            key: const ValueKey('field-price'),
            label: 'Price',
            prefixText: '₹ ',
            initialText: paiseToInput(f.pricePaise),
            errorText: error,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [decimalFormatter],
            onChanged:
                (v) => c.updateForm(
                  (f) => f.copyWith(pricePaise: parseRupeesToPaise(v) ?? 0),
                ),
          ),
          const SizedBox(height: 12),
          if (f.pricePaise >= 100)
            Text(
              'You will receive ${formatPaise(sellerNetPaise(f.pricePaise))} '
              'after the ${platformFeeBps ~/ 100}% platform fee.',
              key: const ValueKey('seller-net'),
              style: theme.textTheme.bodyMedium,
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
