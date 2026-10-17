import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../drawings/domain/drawing_summary.dart';
import '../../drawings/presentation/formatters.dart';
import '../domain/manage_drawings_repository.dart';

enum ManageAction {
  continueEditing,
  viewProgress,
  interested,
  edit,
  remove,
  delete,
}

String statusLabel(DrawingStatus s) => switch (s) {
  DrawingStatus.draft => 'Draft',
  DrawingStatus.processing => 'Processing',
  DrawingStatus.published => 'Published',
  DrawingStatus.underReview => 'Under review',
  DrawingStatus.failed => 'Rejected',
  DrawingStatus.removed => 'Removed',
};

/// Actions offered for a drawing in [status]. Only published drawings can be
/// edited in place (contract: PATCH is limited to title/description/price).
///
/// Paid published drawings also offer the list of interested architects.
List<ManageAction> actionsFor(
  DrawingStatus status, {
  bool paid = false,
}) => switch (status) {
  DrawingStatus.draft => [ManageAction.continueEditing, ManageAction.delete],
  DrawingStatus.processing => [ManageAction.viewProgress],
  DrawingStatus.published => [
    if (paid) ManageAction.interested,
    ManageAction.edit,
    ManageAction.remove,
  ],
  DrawingStatus.underReview => [ManageAction.remove],
  DrawingStatus.failed => [ManageAction.continueEditing, ManageAction.delete],
  DrawingStatus.removed => const [],
};

String actionLabel(ManageAction a, DrawingStatus status) => switch (a) {
  ManageAction.continueEditing =>
    status == DrawingStatus.failed ? 'Fix & retry' : 'Continue editing',
  ManageAction.viewProgress => 'View progress',
  ManageAction.interested => 'Interested',
  ManageAction.edit => 'Edit',
  ManageAction.remove => 'Remove',
  ManageAction.delete => 'Delete',
};

class ManagedDrawingCard extends StatelessWidget {
  const ManagedDrawingCard({
    super.key,
    required this.item,
    required this.onAction,
  });

  final ManagedDrawing item;
  final void Function(ManageAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = item.drawing;
    final showStats =
        d.status == DrawingStatus.published ||
        d.status == DrawingStatus.underReview;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(url: d.previewUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatPlotSize(d)} · ${d.city}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.isFree ? 'Free' : formatPaise(d.pricePaise),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: d.status),
              ],
            ),
            if (showStats) ...[
              const SizedBox(height: 10),
              Row(
                key: ValueKey('stats-${d.id}'),
                children: [
                  _Stat(
                    icon: Icons.visibility_outlined,
                    text: '${item.stats.viewCount} views',
                  ),
                  const SizedBox(width: 16),
                  _Stat(
                    icon: Icons.shopping_bag_outlined,
                    text: '${item.stats.purchaseCount} sales',
                  ),
                  const SizedBox(width: 16),
                  _Stat(
                    icon: Icons.star_outline,
                    text:
                        item.stats.ratingCount == 0
                            ? 'No ratings'
                            : '${formatRating(item.stats.avgRating)} '
                                '(${item.stats.ratingCount})',
                  ),
                ],
              ),
            ],
            if (d.status == DrawingStatus.underReview)
              Padding(
                key: ValueKey('under-review-${d.id}'),
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Under review by admins. A preview looks like another '
                  "architect's drawing; you'll be emailed once it is decided.",
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (d.status == DrawingStatus.failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.failureReason == null || item.failureReason!.isEmpty
                      ? 'Processing failed. Open it to see the reason and '
                          'try again.'
                      : 'Rejected: ${item.failureReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (d.status == DrawingStatus.processing)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final a in actionsFor(d.status, paid: !d.isFree))
                  TextButton(
                    key: ValueKey('action-${a.name}-${d.id}'),
                    onPressed: () => onAction(a),
                    style:
                        a == ManageAction.delete || a == ManageAction.remove
                            ? TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            )
                            : null,
                    child: Text(actionLabel(a, d.status)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.architecture, color: scheme.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child:
            url == null
                ? fallback
                : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => fallback,
                  placeholder: (_, __) => fallback,
                ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DrawingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      DrawingStatus.published => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      DrawingStatus.failed => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
