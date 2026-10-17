import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../data/drawings_providers.dart';
import '../domain/drawing_search_query.dart';
import '../domain/drawing_summary.dart';

part 'drawing_search_controller.g.dart';

/// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
/// distinct query (family key); it is dropped when no screen watches it.
@riverpod
class DrawingSearchController extends _$DrawingSearchController {
  bool _disposed = false;

  @override
  Future<PagedState<DrawingSummary>> build(DrawingSearchQuery query) async {
    ref.onDispose(() => _disposed = true);
    final page = await ref.watch(drawingsRepositoryProvider).search(query);
    return PagedState.fromPage(page);
  }

  /// Loads the next page. After a failure it does nothing until called with
  /// `retry: true`, so a scroll listener cannot hammer a failing endpoint.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    if (current.loadMoreError != null && !retry) return;

    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(drawingsRepositoryProvider)
          .search(query, cursor: current.nextCursor);
      if (_disposed) return;
      state = AsyncData(current.appended(page, (d) => d.id));
    } catch (e) {
      if (_disposed) return;
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }
}
