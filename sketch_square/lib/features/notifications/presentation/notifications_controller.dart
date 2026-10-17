import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../data/notifications_providers.dart';
import '../domain/app_notification.dart';

part 'notifications_controller.g.dart';

class InboxState {
  const InboxState({required this.paged, required this.unreadCount});

  final PagedState<AppNotification> paged;
  final int unreadCount;

  InboxState copyWith({PagedState<AppNotification>? paged, int? unreadCount}) =>
      InboxState(
        paged: paged ?? this.paged,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

/// The in-app inbox (`GET /me/notifications`) with the unread badge count.
@Riverpod(keepAlive: true)
class NotificationsController extends _$NotificationsController {
  @override
  Future<InboxState> build() async {
    ref.watch(currentUserIdProvider);
    return _fetchFirst();
  }

  Future<InboxState> _fetchFirst() async {
    final res = await ref.read(notificationsRepositoryProvider).list();
    return InboxState(
      paged: PagedState.fromPage(res.page),
      unreadCount: res.unreadCount,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.paged.canLoadMore) return;
    state = AsyncData(current.copyWith(paged: current.paged.loadingMore()));
    try {
      final res = await ref
          .read(notificationsRepositoryProvider)
          .list(cursor: current.paged.nextCursor);
      state = AsyncData(
        InboxState(
          paged: current.paged.appended(res.page, (n) => n.id),
          unreadCount: res.unreadCount,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(paged: current.paged.failedMore(toApiException(e))),
      );
    }
  }

  void retryLoadMore() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        paged: PagedState(
          items: current.paged.items,
          nextCursor: current.paged.nextCursor,
        ),
      ),
    );
    loadMore();
  }

  /// Marks one notification read: the row and the badge update immediately and
  /// revert if the call fails (the error is rethrown).
  Future<void> markRead(AppNotification n) async {
    final before = state.valueOrNull;
    if (before == null || n.isRead) return;
    _apply(before, (x) => x.id == n.id, 1);
    try {
      await ref.read(notificationsRepositoryProvider).markRead(ids: [n.id]);
    } catch (e) {
      state = AsyncData(before);
      throw toApiException(e);
    }
  }

  Future<void> markAllRead() async {
    final before = state.valueOrNull;
    if (before == null) return;
    _apply(before, (_) => true, before.unreadCount);
    try {
      await ref.read(notificationsRepositoryProvider).markRead();
    } catch (e) {
      state = AsyncData(before);
      throw toApiException(e);
    }
  }

  void _apply(
    InboxState before,
    bool Function(AppNotification) test,
    int decrement,
  ) {
    final now = DateTime.now().toUtc();
    final items = [
      for (final x in before.paged.items)
        if (test(x) && !x.isRead) x.markedRead(now) else x,
    ];
    final unread = (before.unreadCount - decrement).clamp(0, 1 << 30);
    state = AsyncData(
      InboxState(
        paged: PagedState(
          items: items,
          nextCursor: before.paged.nextCursor,
          isLoadingMore: before.paged.isLoadingMore,
          loadMoreError: before.paged.loadMoreError,
        ),
        unreadCount: unread,
      ),
    );
  }
}

/// Unread badge count; 0 until the inbox has loaded (or if it failed).
@riverpod
int unreadNotificationCount(Ref ref) =>
    ref.watch(notificationsControllerProvider).valueOrNull?.unreadCount ?? 0;
