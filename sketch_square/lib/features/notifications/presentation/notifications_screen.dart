import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_utils.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../domain/app_notification.dart';
import 'notifications_controller.dart';

/// Where tapping [n] should lead, or null when there is nothing to open. Uses
/// the `data` map of the contract; a push payload can reuse it for deep links.
String? routeForNotification(AppNotification n) => switch (n.type) {
  NotificationType.saleMade => AppRoutes.wallet,
  NotificationType.withdrawalStatus => AppRoutes.walletPayouts,
  NotificationType.newReview ||
  NotificationType.interestReceived => AppRoutes.manageDrawings,
  NotificationType.verificationResult || NotificationType.unknown => null,
};

IconData _iconFor(NotificationType t) => switch (t) {
  NotificationType.verificationResult => Icons.verified_user_outlined,
  NotificationType.saleMade => Icons.payments_outlined,
  NotificationType.withdrawalStatus => Icons.account_balance_outlined,
  NotificationType.newReview => Icons.star_outline,
  NotificationType.interestReceived => Icons.thumb_up_outlined,
  NotificationType.unknown => Icons.notifications_none,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _toastError(BuildContext context, Object e) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(toApiException(e).message)));

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    final route = routeForNotification(n);
    if (route != null) pushIfRegistered(context, route);
    try {
      await ref.read(notificationsControllerProvider.notifier).markRead(n);
    } catch (e) {
      if (context.mounted) _toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final unread = inbox.valueOrNull?.unreadCount ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              key: const Key('mark-all-read'),
              onPressed: () async {
                try {
                  await controller.markAllRead();
                } catch (e) {
                  if (context.mounted) _toastError(context, e);
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(notificationsControllerProvider),
            ),
        data: (state) {
          final paged = state.paged;
          if (paged.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: LayoutBuilder(
                builder:
                    (_, c) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: c.maxHeight,
                        child: const BlueprintEmptyState(
                          icon: Icons.notifications_none,
                          title: 'No notifications yet',
                          message:
                              'Sales, reviews, payouts and verification '
                              'updates show up here.',
                        ),
                      ),
                    ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == paged.items.length) {
                  return LoadMoreSentinel(
                    key: ValueKey('notifications-more-${paged.items.length}'),
                    onLoadMore: controller.loadMore,
                    loading: paged.isLoadingMore,
                    errorMessage: paged.loadMoreError?.message,
                    onRetry: controller.retryLoadMore,
                  );
                }
                final n = paged.items[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _open(context, ref, n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;
    return ListTile(
      key: ValueKey('notification-${n.id}'),
      leading: Icon(_iconFor(n.type)),
      title: Text(
        n.title,
        style: n.isRead ? null : const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${n.body}\n${DateFormat.yMMMd().add_jm().format(n.createdAt.toLocal())}',
      ),
      isThreeLine: true,
      trailing:
          n.isRead
              ? null
              : Icon(
                Icons.circle,
                key: ValueKey('unread-${n.id}'),
                size: 10,
                color: theme.colorScheme.primary,
              ),
      onTap: onTap,
    );
  }
}
