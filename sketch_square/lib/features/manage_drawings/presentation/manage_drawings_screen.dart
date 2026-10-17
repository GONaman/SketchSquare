import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../drawings/domain/drawing_summary.dart';
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
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(key: ValueKey('loading')),
                  ),
              error:
                  (e, _) => ErrorRetry(
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
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        for (final f in ManageFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
                child: BlueprintEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title:
                      filter == ManageFilter.all
                          ? 'No drawings yet'
                          : 'Nothing in ${filter.label.toLowerCase()}',
                  message:
                      filter == ManageFilter.all
                          ? 'Upload your first drawing to start selling.'
                          : null,
                  action:
                      filter == ManageFilter.all
                          ? FilledButton(
                            key: const ValueKey('empty-upload'),
                            onPressed: () => context.go(AppRoutes.upload),
                            child: const Text('Upload a drawing'),
                          )
                          : null,
                ),
              ),
            ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.items.length + 1,
      itemBuilder: (context, i) {
        if (i == state.items.length) {
          return _Footer(state: state, controller: controller);
        }
        if (state.canLoadMore && i >= state.items.length - 3) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => controller.loadMore(),
          );
        }
        final item = state.items[i];
        return ManagedDrawingCard(
          key: ValueKey('manage-card-${item.id}'),
          item: item,
          onAction: (a) => _handle(context, ref, item, a),
        );
      },
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
