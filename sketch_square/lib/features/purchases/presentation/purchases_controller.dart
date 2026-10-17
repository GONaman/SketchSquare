import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../data/purchases_providers.dart';
import '../domain/purchase_models.dart';

part 'purchases_controller.g.dart';

/// The buyer's library (`GET /me/purchases`), newest first, cursor-paged.
@Riverpod(keepAlive: true)
class PurchasesController extends _$PurchasesController {
  @override
  Future<PagedState<PurchaseItem>> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(purchasesRepositoryProvider).list();
    return PagedState.fromPage(page);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await ref.read(purchasesRepositoryProvider).list();
      return PagedState.fromPage(page);
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(purchasesRepositoryProvider)
          .list(cursor: current.nextCursor);
      state = AsyncData(current.appended(page, (p) => p.key));
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
}
