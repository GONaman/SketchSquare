import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/money.dart';
import '../../domain/sheet_upload_target.dart';
import '../upload_flow_controller.dart';
import '../upload_flow_state.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final theme = Theme.of(context);
    final f = s.form;
    final blockers = s.publishBlockers;
    final category =
        s.categories.where((e) => e.id == f.categoryId).firstOrNull?.name ??
        '—';
    final area = f.plotAreaSqft;

    Widget section(String title, UploadStep step, List<Widget> children) =>
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    TextButton(
                      key: ValueKey('edit-${step.name}'),
                      onPressed: () => c.goToStep(step),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                ...children,
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (blockers.isNotEmpty)
          Container(
            key: const ValueKey('publish-blockers'),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fix these before publishing',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                for (final b in blockers)
                  Text(
                    '• $b',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
              ],
            ),
          ),
        section('Details', UploadStep.details, [
          Text(f.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(f.description, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(
            [
              category,
              if (f.city.trim().isNotEmpty) f.city.trim(),
              if (area != null) '${area.round()} sq ft',
              if (f.floors != null) '${f.floors} floor(s)',
              if (f.bedrooms != null) '${f.bedrooms} bedroom(s)',
              if (f.facing != null) '${f.facing} facing',
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          if (f.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: [for (final t in f.tags) Chip(label: Text(t))],
              ),
            ),
        ]),
        section('Sheets', UploadStep.sheets, [
          if (s.sheets.isEmpty) const Text('No sheets'),
          for (final i in s.sheets)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${i.name} · ${i.type.label}${i.isPreview ? ' · preview' : ''}',
              ),
            ),
        ]),
        section('Pricing', UploadStep.pricing, [
          Text(
            f.isFree ? 'Free' : formatPaise(f.pricePaise),
            key: const ValueKey('review-price'),
            style: theme.textTheme.titleSmall,
          ),
          if (!f.isFree && f.pricePaise >= 100)
            Text(
              'You receive ${formatPaise(sellerNetPaise(f.pricePaise))} '
              'after the platform fee.',
              style: theme.textTheme.bodySmall,
            ),
        ]),
        Text(
          'Publishing generates watermarked previews. This can take a minute.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Shown instead of the steps once the drawing is being processed or finished.
class PublishStatusView extends ConsumerWidget {
  const PublishStatusView({super.key, required this.onStartNew});

  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final theme = Theme.of(context);

    Widget layout({
      required Widget leading,
      required String title,
      String? message,
      required List<Widget> actions,
    }) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            ...actions,
          ],
        ),
      ),
    );

    switch (s.phase) {
      case PublishPhase.idle:
        return const SizedBox.shrink();
      case PublishPhase.publishing:
      case PublishPhase.processing:
        return layout(
          leading:
              s.pollStalled
                  ? Icon(
                    Icons.hourglass_bottom,
                    size: 48,
                    color: theme.colorScheme.primary,
                  )
                  : const CircularProgressIndicator(
                    key: ValueKey('processing-spinner'),
                  ),
          title:
              s.pollStalled ? 'Still processing…' : 'Generating your previews…',
          message:
              s.pollStalled
                  ? "We couldn't get an update. Your drawing is safe and "
                      'processing continues on our side.'
                  : 'Watermarking and rendering your sheets. You can leave '
                      'this screen; your drawing will be here when you return.',
          actions: [
            if (s.pollStalled)
              FilledButton(
                key: const ValueKey('check-again'),
                onPressed: c.resumePolling,
                child: const Text('Check again'),
              ),
          ],
        );
      case PublishPhase.published:
        return layout(
          leading: Icon(
            Icons.check_circle,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          title: 'Your drawing is live',
          message: '${s.form.title} is now visible in the marketplace.',
          actions: [
            FilledButton(
              key: const ValueKey('start-new'),
              onPressed: onStartNew,
              child: const Text('Upload another drawing'),
            ),
          ],
        );
      case PublishPhase.underReview:
        return layout(
          leading: Icon(
            Icons.fact_check_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          title: 'Submitted for review',
          message:
              'Our team will review ${s.form.title} before it goes live. '
              "You'll be notified when it is approved.",
          actions: [
            FilledButton(
              key: const ValueKey('start-new'),
              onPressed: onStartNew,
              child: const Text('Upload another drawing'),
            ),
          ],
        );
      case PublishPhase.failed:
        return layout(
          leading: Icon(
            Icons.error_outline,
            size: 56,
            color: theme.colorScheme.error,
          ),
          title: "We couldn't process this drawing",
          message: s.failureReason ?? 'Something went wrong while processing.',
          actions: [
            FilledButton(
              key: const ValueKey('retry-publish'),
              onPressed: c.retryPublish,
              child: const Text('Try again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('edit-after-failure'),
              onPressed: c.editAfterFailure,
              child: const Text('Edit drawing'),
            ),
          ],
        );
    }
  }
}
