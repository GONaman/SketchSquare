import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../../interest/presentation/interested_sheet.dart';
import '../data/manage_drawings_providers.dart';
import '../domain/manage_drawings_repository.dart';
import 'edit_published_sheet.dart';
import 'manage_drawings_controller.dart';
import 'managed_drawing_card.dart';

/// Seller's drawing list (`AppRoutes.manageDrawings`): filter by status, edit
/// published drawings, continue drafts, remove/delete.
class ManageDrawingsScreen extends ConsumerWidget {
  const ManageDrawingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(manageFilterControllerProvider);
    final list = ref.watch(managedDrawingsControllerProvider(filter));
    final controller = ref.read(
      managedDrawingsControllerProvider(filter).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Manage drawings')),
      body: Column(
        children: [
          _FilterBar(
            selected: filter,
            onSelected:
                ref.read(manageFilterControllerProvider.notifier).select,
          ),
          Expanded(
            child: list.when(
              loading: () => const _LoadingList(),
              error:
                  (e, _) => ErrorState(
                    message: toApiException(e).message,
                    onRetry:
                        () => ref.invalidate(
                          managedDrawingsControllerProvider(filter),
                        ),
                  ),
              data:
                  (state) => RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: _DrawingList(
                      state: state,
                      filter: filter,
                      controller: controller,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final ManageFilter selected;
  final ValueChanged<ManageFilter> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      children: [
        for (final f in ManageFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              key: ValueKey('filter-${f.name}'),
              label: Text(f.label),
              selected: f == selected,
              onSelected: (_) => onSelected(f),
            ),
          ),
      ],
    ),
  );
}

class _DrawingList extends ConsumerWidget {
  const _DrawingList({
    required this.state,
    required this.filter,
    required this.controller,
  });

  final PagedState<ManagedDrawing> state;
  final ManageFilter filter;
  final ManagedDrawingsController controller;

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    ManagedDrawing item,
    ManageAction action,
  ) async {
    final d = item.drawing;
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case ManageAction.continueEditing:
      case ManageAction.viewProgress:
        context.go('${AppRoutes.upload}?draft=${d.id}');
      case ManageAction.interested:
        await showInterestedSheet(
          context,
          drawingId: d.id,
          drawingTitle: d.title,
        );
      case ManageAction.edit:
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder:
              (_) => EditPublishedSheet(
                drawingId: d.id,
                repository: ref.read(manageDrawingsRepositoryProvider),
                onSave:
                    (t, desc, price) => controller.updatePublished(
                      d.id,
                      title: t,
                      description: desc,
                      pricePaise: price,
                    ),
              ),
        );
        if (saved == true) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Changes saved')),
          );
        }
      case ManageAction.remove:
      case ManageAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmRemoveDialog(drawing: d, action: action),
        );
        if (confirmed != true) return;
        try {
          await controller.remove(d.id);
          messenger.showSnackBar(
            SnackBar(content: Text('"${d.title}" removed')),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text(toApiException(e).message)),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) {
      return LayoutBuilder(
        builder:
            (_, c) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: c.maxHeight,
                child: _EmptyView(filter: filter),
              ),
            ),
      );
    }
    final showSummary = filter == ManageFilter.all && !state.canLoadMore;
    final lead = showSummary ? 1 : 0;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: state.items.length + lead + 1,
      itemBuilder: (context, i) {
        if (i == 0 && showSummary) {
          return _SummaryStrip(items: state.items);
        }
        final index = i - lead;
        if (index == state.items.length) {
          return _Footer(state: state, controller: controller);
        }
        if (state.canLoadMore && index >= state.items.length - 3) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => controller.loadMore(),
          );
        }
        final item = state.items[index];
        return ManagedDrawingCard(
          key: ValueKey('manage-card-${item.id}'),
          item: item,
          onAction: (a) => _handle(context, ref, item, a),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter});

  final ManageFilter filter;

  @override
  Widget build(BuildContext context) {
    final all = filter == ManageFilter.all;
    return EmptyState(
      icon: switch (filter) {
        ManageFilter.all => Icons.inventory_2_outlined,
        ManageFilter.drafts => Icons.edit_note_rounded,
        ManageFilter.processing => Icons.autorenew_rounded,
        ManageFilter.published => Icons.storefront_outlined,
        ManageFilter.underReview => Icons.hourglass_top_rounded,
        ManageFilter.rejected => Icons.report_gmailerrorred_outlined,
      },
      title:
          all ? 'No drawings yet' : 'Nothing in ${filter.label.toLowerCase()}',
      message:
          all
              ? 'Upload your first drawing to start selling. Buyers find it by '
                  'plot size.'
              : 'Drawings with this status will show up here.',
      action:
          all
              ? PrimaryButton(
                key: const ValueKey('empty-upload'),
                label: 'Upload a drawing',
                icon: Icons.add_rounded,
                expand: false,
                onPressed: () => context.go(AppRoutes.upload),
              )
              : null,
    );
  }
}

/// Totals across every drawing, shown once the whole list is loaded.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});

  final List<ManagedDrawing> items;

  @override
  Widget build(BuildContext context) {
    final live = items.where(
      (m) => m.drawing.status == DrawingStatus.published,
    );
    final views = items.fold<int>(0, (n, m) => n + m.stats.viewCount);
    final sales = items.fold<int>(0, (n, m) => n + m.stats.purchaseCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: IntrinsicHeight(
        key: const ValueKey('manage-summary'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatTile(
                value: '${live.length}',
                label: 'Live',
                icon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                value: '$views',
                label: 'Views',
                icon: Icons.visibility_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                value: '$sales',
                label: 'Sales',
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      key: ValueKey('loading'),
      physics: NeverScrollableScrollPhysics(),
      child: Shimmer(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _SkeletonCard(),
              SizedBox(height: AppSpacing.md),
              _SkeletonCard(),
              SizedBox(height: AppSpacing.md),
              _SkeletonCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      style: AppCardStyle.outlined,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 76, height: 76, radius: AppRadius.sm),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 72, height: 18, radius: AppRadius.pill),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 16),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.controller});

  final PagedState<ManagedDrawing> state;
  final ManagedDrawingsController controller;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          key: const ValueKey('retry-more'),
          onPressed: () => controller.loadMore(retry: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Couldn’t load more. Retry'),
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _ConfirmRemoveDialog extends StatelessWidget {
  const _ConfirmRemoveDialog({required this.drawing, required this.action});

  final DrawingSummary drawing;
  final ManageAction action;

  @override
  Widget build(BuildContext context) {
    final isDraft =
        drawing.status == DrawingStatus.draft ||
        drawing.status == DrawingStatus.failed;
    final verb = action == ManageAction.delete ? 'Delete' : 'Remove';
    return AlertDialog(
      title: Text('$verb "${drawing.title}"?'),
      content: Text(
        isDraft
            ? 'This permanently deletes the drawing and its uploaded sheets.'
            : 'It will no longer be listed in the marketplace. People who '
                'already bought it keep their access.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-remove'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(verb),
        ),
      ],
    );
  }
}
