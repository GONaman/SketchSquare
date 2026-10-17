import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart' hide formatPaise;
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

IconData actionIcon(ManageAction a) => switch (a) {
  ManageAction.continueEditing => Icons.edit_note_rounded,
  ManageAction.viewProgress => Icons.timelapse_rounded,
  ManageAction.interested => Icons.groups_2_outlined,
  ManageAction.edit => Icons.edit_outlined,
  ManageAction.remove => Icons.visibility_off_outlined,
  ManageAction.delete => Icons.delete_outline_rounded,
};

StatusTone statusTone(DrawingStatus s) => switch (s) {
  DrawingStatus.published => StatusTone.success,
  DrawingStatus.processing => StatusTone.info,
  DrawingStatus.underReview => StatusTone.warning,
  DrawingStatus.failed => StatusTone.danger,
  DrawingStatus.draft || DrawingStatus.removed => StatusTone.neutral,
};

IconData statusIcon(DrawingStatus s) => switch (s) {
  DrawingStatus.published => Icons.check_circle_outline_rounded,
  DrawingStatus.processing => Icons.autorenew_rounded,
  DrawingStatus.underReview => Icons.hourglass_top_rounded,
  DrawingStatus.failed => Icons.error_outline_rounded,
  DrawingStatus.draft => Icons.edit_note_rounded,
  DrawingStatus.removed => Icons.visibility_off_outlined,
};

/// One drawing in the seller's list: thumbnail, status pill, stats and the
/// actions that apply to its current status.
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
    final scheme = theme.colorScheme;
    final d = item.drawing;
    final showStats =
        d.status == DrawingStatus.published ||
        d.status == DrawingStatus.underReview;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 1,
      ),
      child: AppCard(
        style: AppCardStyle.outlined,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawingThumbnail(url: d.previewUrl, size: 76),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: StatusPill(
                          label: statusLabel(d.status),
                          tone: statusTone(d.status),
                          icon: statusIcon(d.status),
                          dense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        d.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatPlotSize(d)} · ${d.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  d.isFree ? 'Free' : formatPaise(d.pricePaise),
                  style: theme.textTheme.titleSmall?.tabular.copyWith(
                    color:
                        d.isFree
                            ? AppSemanticColors.of(context).success
                            : scheme.onSurface,
                  ),
                ),
              ],
            ),
            if (showStats) ...[
              const SizedBox(height: AppSpacing.md),
              _StatsStrip(key: ValueKey('stats-${d.id}'), stats: item.stats),
            ],
            if (d.status == DrawingStatus.underReview)
              _Notice(
                key: ValueKey('under-review-${d.id}'),
                icon: Icons.hourglass_top_rounded,
                tone: StatusTone.warning,
                text:
                    'Under review by admins. A preview looks like another '
                    "architect's drawing; you'll be emailed once it is decided.",
              ),
            if (d.status == DrawingStatus.failed)
              _Notice(
                icon: Icons.error_outline_rounded,
                tone: StatusTone.danger,
                text:
                    item.failureReason == null || item.failureReason!.isEmpty
                        ? 'Processing failed. Open it to see the reason and '
                            'try again.'
                        : 'Rejected: ${item.failureReason}',
              ),
            if (d.status == DrawingStatus.processing)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                  child: LinearProgressIndicator(minHeight: 6),
                ),
              ),
            _Actions(
              status: d.status,
              id: d.id,
              paid: !d.isFree,
              onAction: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({super.key, required this.stats});

  final DrawingStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _Stat(
              icon: Icons.visibility_outlined,
              text: '${stats.viewCount} views',
            ),
            _Stat(
              icon: Icons.shopping_bag_outlined,
              text: '${stats.purchaseCount} sales',
            ),
            _Stat(
              icon: Icons.star_outline_rounded,
              text:
                  stats.ratingCount == 0
                      ? 'No ratings'
                      : '${formatRating(stats.avgRating)} '
                          '(${stats.ratingCount})',
            ),
          ],
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
        const SizedBox(width: AppSpacing.xs + 1),
        Text(text, style: theme.textTheme.bodySmall?.tabular),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.tone,
    required this.text,
  });

  final IconData icon;
  final StatusTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sem = AppSemanticColors.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.warning => (sem.warningContainer, scheme.onSurface),
      _ => (scheme.surfaceContainerLow, scheme.onSurface),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.status,
    required this.id,
    required this.paid,
    required this.onAction,
  });

  final DrawingStatus status;
  final String id;
  final bool paid;
  final void Function(ManageAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final actions = actionsFor(status, paid: paid);
    if (actions.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final a in actions)
            if (a == ManageAction.delete || a == ManageAction.remove)
              TextButton.icon(
                key: ValueKey('action-${a.name}-$id'),
                onPressed: () => onAction(a),
                icon: Icon(actionIcon(a), size: 18),
                label: Text(actionLabel(a, status)),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  minimumSize: const Size(48, 48),
                ),
              )
            else
              SecondaryButton(
                key: ValueKey('action-${a.name}-$id'),
                label: actionLabel(a, status),
                icon: actionIcon(a),
                expand: false,
                onPressed: () => onAction(a),
              ),
        ],
      ),
    );
  }
}
