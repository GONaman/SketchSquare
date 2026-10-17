import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../drawings/data/drawings_providers.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../data/favorites_providers.dart';

part 'favorites_controller.g.dart';

/// The user's favorite drawings (`GET /me/favorites`), newest favorite first.
@Riverpod(keepAlive: true)
class FavoritesController extends _$FavoritesController {
  @override
  Future<PagedState<DrawingSummary>> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(favoritesRepositoryProvider).list();
    return PagedState.fromPage(page);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await ref.read(favoritesRepositoryProvider).list();
      return PagedState.fromPage(page);
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(favoritesRepositoryProvider)
          .list(cursor: current.nextCursor);
      state = AsyncData(current.appended(page, (d) => d.id));
    } catch (e) {
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }

  /// Clears a failed "load more" so scrolling retries.
  void retryLoadMore() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      PagedState(items: current.items, nextCursor: current.nextCursor),
    );
    loadMore();
  }

  /// Un-favorites [drawing]: the tile disappears immediately and comes back at
  /// its old position if the server call fails (the error is rethrown).
  Future<void> remove(DrawingSummary drawing) async {
    final before = state.valueOrNull;
    if (before == null) return;
    final index = before.items.indexWhere((d) => d.id == drawing.id);
    if (index < 0) return;
    state = AsyncData(
      PagedState(
        items: [...before.items]..removeAt(index),
        nextCursor: before.nextCursor,
      ),
    );
    try {
      await ref
          .read(drawingActionsRepositoryProvider)
          .setFavorite(drawing.id, favorite: false);
    } catch (e) {
      final now = state.valueOrNull;
      if (now != null && !now.items.any((d) => d.id == drawing.id)) {
        final items = [...now.items]
          ..insert(index.clamp(0, now.items.length), drawing);
        state = AsyncData(PagedState(items: items, nextCursor: now.nextCursor));
      }
      throw toApiException(e);
    }
  }
}
