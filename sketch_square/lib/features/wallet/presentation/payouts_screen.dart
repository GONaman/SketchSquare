import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../upload/domain/money.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(withdrawalsControllerProvider),
            ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return const BlueprintEmptyState(
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
              padding: const EdgeInsets.all(16),
              children: [
                for (final w in paged.items) WithdrawalTile(withdrawal: w),
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
    final status = withdrawal.status;
    final color = switch (status) {
      WithdrawalStatus.paid => Colors.green.shade700,
      WithdrawalStatus.failed => theme.colorScheme.error,
      _ => theme.colorScheme.primary,
    };
    return ListTile(
      key: ValueKey('payout-${withdrawal.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.payments_outlined, color: color),
      title: Text(formatPaise(withdrawal.amountPaise)),
      subtitle: Text(formatWalletDate(withdrawal.createdAt)),
      trailing: Chip(
        label: Text(status.label),
        labelStyle: TextStyle(color: color),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
