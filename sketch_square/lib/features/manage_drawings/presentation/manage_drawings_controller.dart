import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../../core/pagination/paged_state.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../data/manage_drawings_providers.dart';
import '../domain/manage_drawings_repository.dart';

part 'manage_drawings_controller.g.dart';

/// Status chips of the manage list. `rejected` maps to the contract's FAILED
/// (processing/moderation failure); REMOVED drawings are never listed.
enum ManageFilter {
  all('All', null),
  drafts('Drafts', DrawingStatus.draft),
  processing('Processing', DrawingStatus.processing),
  published('Published', DrawingStatus.published),
  underReview('Under review', DrawingStatus.underReview),
  rejected('Rejected', DrawingStatus.failed);

  const ManageFilter(this.label, this.status);
  final String label;
  final DrawingStatus? status;
}

@riverpod
class ManageFilterController extends _$ManageFilterController {
  @override
  ManageFilter build() => ManageFilter.all;

  void select(ManageFilter filter) => state = filter;
}

/// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
@riverpod
class ManagedDrawingsController extends _$ManagedDrawingsController {
  bool _disposed = false;

  @override
  Future<PagedState<ManagedDrawing>> build(ManageFilter filter) async {
    ref.onDispose(() => _disposed = true);
    // A different account must never see the previous one's list.
    ref.watch(currentUserIdProvider);
    final page = await ref
        .watch(manageDrawingsRepositoryProvider)
        .list(status: filter.status);
    return PagedState.fromPage(_withoutRemoved(page));
  }

  CursorPage<ManagedDrawing> _withoutRemoved(CursorPage<ManagedDrawing> page) =>
      CursorPage(
        items: [
          for (final m in page.items)
            if (m.drawing.status != DrawingStatus.removed) m,
        ],
        nextCursor: page.nextCursor,
      );

  /// Loads the next page; after a failure it waits for `retry: true`.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    if (current.loadMoreError != null && !retry) return;

    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(manageDrawingsRepositoryProvider)
          .list(status: filter.status, cursor: current.nextCursor);
      if (_disposed) return;
      state = AsyncData(current.appended(_withoutRemoved(page), (m) => m.id));
    } catch (e) {
      if (_disposed) return;
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Deletes the drawing (REMOVED server-side) and drops it from the list.
  /// Throws [ApiException] on failure, leaving the list untouched.
  Future<void> remove(String id) async {
    await ref.read(manageDrawingsRepositoryProvider).delete(id);
    _replaceItems(
      (items) => [
        for (final m in items)
          if (m.id != id) m,
      ],
    );
  }

  /// Saves the editable fields of a published drawing and reflects them in the list.
  Future<void> updatePublished(
    String id, {
    required String title,
    required String description,
    required int pricePaise,
  }) async {
    await ref
        .read(manageDrawingsRepositoryProvider)
        .updatePublished(
          id,
          title: title,
          description: description,
          pricePaise: pricePaise,
        );
    _replaceItems(
      (items) => [
        for (final m in items)
          if (m.id == id)
            m.withDrawing(
              m.drawing.copyWith(title: title.trim(), pricePaise: pricePaise),
            )
          else
            m,
      ],
    );
  }

  void _replaceItems(
    List<ManagedDrawing> Function(List<ManagedDrawing>) update,
  ) {
    final current = state.valueOrNull;
    if (current == null || _disposed) return;
    state = AsyncData(
      PagedState(
        items: update(current.items),
        nextCursor: current.nextCursor,
        isLoadingMore: current.isLoadingMore,
        loadMoreError: current.loadMoreError,
      ),
    );
  }
}
