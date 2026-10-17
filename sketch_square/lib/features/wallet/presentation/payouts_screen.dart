import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/wallet_models.dart';
import 'wallet_controllers.dart';
import 'wallet_screen.dart';

/// Payout history (`GET /wallet/withdrawals`).
class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = ref.watch(withdrawalsControllerProvider);
    final notifier = ref.read(withdrawalsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout history')),
      body: payouts.when(
        loading: () => const ListRowSkeleton(count: 4),
        error:
            (e, _) => ErrorState(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(withdrawalsControllerProvider),
            ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No payouts yet',
              message: 'Withdrawals you request appear here with their status.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(withdrawalsControllerProvider);
              await ref.read(withdrawalsControllerProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < paged.items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 72,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        WithdrawalTile(withdrawal: paged.items[i]),
                      ],
                    ],
                  ),
                ),
                if (paged.hasMore)
                  LoadMoreSentinel(
                    key: ValueKey('payouts-more-${paged.items.length}'),
                    loading: paged.isLoadingMore,
                    errorMessage: paged.loadMoreError?.message,
                    onLoadMore: notifier.loadMore,
                    onRetry: notifier.retryLoadMore,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WithdrawalTile extends StatelessWidget {
  const WithdrawalTile({super.key, required this.withdrawal});
  final Withdrawal withdrawal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = withdrawal.status;
    final (tone, icon) = switch (status) {
      WithdrawalStatus.paid => (StatusTone.success, Icons.check_circle_outline),
      WithdrawalStatus.failed => (StatusTone.danger, Icons.error_outline),
      WithdrawalStatus.processing => (StatusTone.info, Icons.sync_rounded),
      WithdrawalStatus.requested => (StatusTone.warning, Icons.schedule),
    };
    return Padding(
      key: ValueKey('payout-${withdrawal.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(
                Icons.payments_outlined,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPaise(withdrawal.amountPaise),
                  style: theme.textTheme.titleSmall?.tabular,
                ),
                const SizedBox(height: 2),
                Text(
                  formatWalletDate(withdrawal.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(label: status.label, tone: tone, icon: icon, dense: true),
        ],
      ),
    );
  }
}
