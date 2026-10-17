import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/widgets.dart' hide formatPaise;
import '../../domain/money.dart';
import '../../domain/sheet_upload_target.dart';
import '../upload_flow_controller.dart';
import '../upload_flow_state.dart';
import 'form_widgets.dart';
import 'listing_preview.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = s.form;
    final blockers = s.publishBlockers;
    final category =
        s.categories.where((e) => e.id == f.categoryId).firstOrNull?.name ??
        '—';
    final area = f.plotAreaSqft;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget card(String title, UploadStep step, List<Widget> children) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    TextButton.icon(
                      key: ValueKey('edit-${step.name}'),
                      onPressed: () => c.goToStep(step),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        );

    final facts = [
      category,
      if (f.city.trim().isNotEmpty) f.city.trim(),
      if (area != null) '${area.round()} sq ft',
      if (f.floors != null) '${f.floors} floor(s)',
      if (f.bedrooms != null) '${f.bedrooms} bedroom(s)',
      if (f.facing != null) '${f.facing} facing',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepIntro(
          kicker: 'STEP 4 OF 4',
          title: 'Review & publish',
          subtitle: 'One last look. Buyers will see exactly this.',
        ),
        if (blockers.isNotEmpty)
          Container(
            key: const ValueKey('publish-blockers'),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Fix these before publishing',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final b in blockers)
                  Text(
                    '• $b',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: ListingPreviewStage(),
        ),
        card('Details', UploadStep.details, [
          Text(f.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(f.description, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Text(facts.join(' · '), style: muted),
          if (f.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [for (final t in f.tags) Chip(label: Text(t))],
              ),
            ),
        ]),
        card('Sheets', UploadStep.sheets, [
          if (s.sheets.isEmpty) const Text('No sheets'),
          for (final i in s.sheets)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${i.name} · ${i.type.label}${i.isPreview ? ' · preview' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ]),
        card('Pricing', UploadStep.pricing, [
          Text(
            f.isFree ? 'Free' : formatPaise(f.pricePaise),
            key: const ValueKey('review-price'),
            style: theme.textTheme.titleLarge?.tabular,
          ),
          if (!f.isFree && f.pricePaise >= 100)
            Text(
              'You receive ${formatPaise(sellerNetPaise(f.pricePaise))} '
              'after the platform fee.',
              style: muted,
            ),
        ]),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Publishing generates watermarked previews. This can take a '
                'minute.',
                style: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
