import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/widgets.dart' hide formatPaise;
import '../../domain/contribution_status.dart';
import '../../domain/money.dart';
import '../upload_flow_controller.dart';
import 'form_widgets.dart';
import 'listing_preview.dart';

class PricingStep extends ConsumerWidget {
  const PricingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final f = s.form;
    final error = s.showErrors ? s.pricingErrors['price'] : null;
    final contribution = s.contribution;
    final blocked = contribution != null && !contribution.canPublishPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepIntro(
          kicker: 'STEP 3 OF 4',
          title: 'Set your price',
          subtitle:
              'Free drawings reach more buyers; paid drawings earn you '
              'money. You can change this later.',
        ),
        if (contribution != null && contribution.ruleActive)
          _ContributionNote(
            key: const ValueKey('contribution-banner'),
            status: contribution,
          ),
        if (s.paidBlockedByContribution)
          MessageBanner(
            key: const ValueKey('contribution-blocked'),
            message: contribution!.blockedMessage,
          ),
        FormSection(
          title: 'Pricing',
          icon: Icons.sell_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                key: const ValueKey('price-mode'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ModeTile(
                        label: 'Free',
                        caption: 'Anyone can download',
                        icon: Icons.volunteer_activism_outlined,
                        selected: f.isFree,
                        onTap:
                            () => c.updateForm((f) => f.copyWith(isFree: true)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ModeTile(
                        label: 'Paid',
                        caption: blocked ? 'Locked for now' : 'Earn per sale',
                        icon: Icons.currency_rupee,
                        selected: !f.isFree && !blocked,
                        enabled: !blocked,
                        onTap:
                            () =>
                                c.updateForm((f) => f.copyWith(isFree: false)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (f.isFree)
                _FreeNote(onTheme: Theme.of(context))
              else if (blocked)
                Text(
                  'Choose Free to continue with this drawing.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                FormTextField(
                  key: const ValueKey('field-price'),
                  label: 'Price',
                  prefixText: '₹ ',
                  tabularFigures: true,
                  initialText: paiseToInput(f.pricePaise),
                  errorText: error,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalFormatter],
                  onChanged:
                      (v) => c.updateForm(
                        (f) =>
                            f.copyWith(pricePaise: parseRupeesToPaise(v) ?? 0),
                      ),
                ),
                if (f.pricePaise >= 100) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FeeBreakdown(pricePaise: f.pricePaise),
                ],
              ],
            ],
          ),
        ),
        const ListingPreviewStage(
          caption: 'Updates as you type. Photos come from your sheets.',
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg =
        !enabled
            ? scheme.onSurface.withValues(alpha: 0.38)
            : selected
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: fg),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: scheme.primary,
                        )
                      else
                        Icon(
                          enabled
                              ? Icons.radio_button_unchecked
                              : Icons.lock_outline,
                          size: 20,
                          color: fg.withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                  Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: enabled ? 0.8 : 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeNote extends StatelessWidget {
  const _FreeNote({required this.onTheme});

  final ThemeData onTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = onTheme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.favorite_outline, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Anyone can download this drawing for free. You will not earn '
            'from it, but it builds your reputation and counts towards '
            'unlocking paid listings.',
            style: onTheme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown({required this.pricePaise});

  final int pricePaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final net = sellerNetPaise(pricePaise);
    final fee = pricePaise - net;

    Widget row(String label, Widget value, {TextStyle? labelStyle}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [Expanded(child: Text(label, style: labelStyle)), value],
      ),
    );

    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            row(
              'Buyer pays',
              Text(formatPaise(pricePaise), style: muted?.tabular),
              labelStyle: muted,
            ),
            row(
              'Platform fee (${platformFeeBps ~/ 100}%)',
              Text('− ${formatPaise(fee)}', style: muted?.tabular),
              labelStyle: muted,
            ),
            Divider(height: AppSpacing.lg, color: scheme.outlineVariant),
            row(
              'You receive',
              Text(
                formatPaise(net),
                key: const ValueKey('seller-net'),
                style: theme.textTheme.titleMedium?.tabular,
              ),
              labelStyle: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionNote extends StatelessWidget {
  const _ContributionNote({super.key, required this.status});

  final ContributionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        style: AppCardStyle.tonal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.handshake_outlined, size: 22, color: scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Give one, earn one', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(status.explanation, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${status.freePublished} free published · '
                    '${status.paidPublished} paid published',
                    style: theme.textTheme.labelMedium?.tabular.copyWith(
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
