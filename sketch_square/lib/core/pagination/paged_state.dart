import '../network/api_exception.dart';
import '../network/cursor_page.dart';

/// Accumulated cursor-paginated list for infinite scroll. Hold it as the data
/// of an `AsyncNotifier`: the first page load is the `AsyncValue` loading/error
/// state, later pages use [isLoadingMore] / [loadMoreError].
class PagedState<T> {
  const PagedState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory PagedState.fromPage(CursorPage<T> page) =>
      PagedState(items: page.items, nextCursor: page.nextCursor);

  final List<T> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final ApiException? loadMoreError;

  bool get hasMore => nextCursor != null;

  /// False while a page is in flight or after a failure (until a retry).
  bool get canLoadMore => hasMore && !isLoadingMore && loadMoreError == null;

  PagedState<T> loadingMore() =>
      PagedState(items: items, nextCursor: nextCursor, isLoadingMore: true);

  PagedState<T> failedMore(ApiException error) =>
      PagedState(items: items, nextCursor: nextCursor, loadMoreError: error);

  /// Appends [page], skipping items whose [idOf] is already present
  /// (a shifting cursor window must never duplicate tiles).
  PagedState<T> appended(CursorPage<T> page, String Function(T) idOf) {
    final seen = {for (final i in items) idOf(i)};
    return PagedState(
      items: [
        ...items,
        for (final i in page.items)
          if (seen.add(idOf(i))) i,
      ],
      nextCursor: page.nextCursor,
    );
  }
}
