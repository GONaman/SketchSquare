import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/pagination/paged_state.dart';

void main() {
  const error = ApiException(code: ApiErrorCodes.network, message: 'down');

  test('fromPage exposes cursor and canLoadMore', () {
    final s = PagedState<String>.fromPage(
      const CursorPage(items: ['a'], nextCursor: 'c1'),
    );
    expect(s.hasMore, isTrue);
    expect(s.canLoadMore, isTrue);
    expect(
      PagedState<String>.fromPage(const CursorPage(items: [])).canLoadMore,
      isFalse,
    );
  });

  test('canLoadMore is false while loading and after an error', () {
    final s = PagedState<String>.fromPage(
      const CursorPage(items: ['a'], nextCursor: 'c1'),
    );
    expect(s.loadingMore().canLoadMore, isFalse);
    expect(s.failedMore(error).canLoadMore, isFalse);
    expect(s.failedMore(error).loadMoreError, error);
  });

  test('appended keeps order, drops duplicate ids and clears flags', () {
    final s = PagedState<String>.fromPage(
      const CursorPage(items: ['a', 'b'], nextCursor: 'c1'),
    ).failedMore(error);
    final next = s.appended(
      const CursorPage(items: ['b', 'c'], nextCursor: null),
      (i) => i,
    );
    expect(next.items, ['a', 'b', 'c']);
    expect(next.hasMore, isFalse);
    expect(next.loadMoreError, isNull);
    expect(next.isLoadingMore, isFalse);
  });
}
