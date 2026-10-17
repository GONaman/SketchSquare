import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/admin_verification.dart';
import 'admin_providers.dart';

String adminVerificationPath(String id) =>
    '${AppRoutes.admin}/verification/$id';

/// ADMIN only: pending architect verification requests.
class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingVerificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pending verifications')),
      body: async.when(
        loading: () => const ListRowSkeleton(count: 4),
        error:
            (e, _) => ErrorState(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(pendingVerificationsProvider),
            ),
        data: (paged) {
          Future<void> refresh() async {
            ref.invalidate(pendingVerificationsProvider);
            await ref.read(pendingVerificationsProvider.future);
          }

          if (paged.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: LayoutBuilder(
                builder:
                    (context, c) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: c.maxHeight,
                        child: const EmptyState(
                          icon: Icons.verified_outlined,
                          title: 'All caught up',
                          message: 'No architects are waiting for review.',
                        ),
                      ),
                    ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                if (i == paged.items.length) {
                  final notifier = ref.read(
                    pendingVerificationsProvider.notifier,
                  );
                  return LoadMoreSentinel(
                    key: ValueKey('verifications-more-${paged.items.length}'),
                    loading: paged.isLoadingMore,
                    errorMessage: paged.loadMoreError?.message,
                    onLoadMore: notifier.loadMore,
                    onRetry: notifier.loadMore,
                  );
                }
                return _VerificationTile(paged.items[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile(this.item);

  final AdminVerification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final city = item.user.city;
    return AppCard(
      onTap: () => context.push(adminVerificationPath(item.id)),
      child: Row(
        children: [
          AppAvatar(name: item.user.fullName, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.user.fullName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    'COA ${item.coaRegistrationNumber}',
                    if (city != null && city.isNotEmpty) city,
                  ].join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const StatusPill(
                      label: 'Pending',
                      tone: StatusTone.warning,
                      icon: Icons.schedule,
                      dense: true,
                    ),
                    Text(
                      'Submitted ${DateFormat.yMMMd().format(item.submittedAt.toLocal())}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}
