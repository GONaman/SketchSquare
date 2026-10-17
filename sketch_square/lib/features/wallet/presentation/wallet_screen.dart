import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../upload/domain/money.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_validators.dart';
import 'wallet_controllers.dart';
import 'withdraw_sheet.dart';

final _dateFormat = DateFormat('d MMM y, h:mm a');

String formatWalletDate(DateTime d) => _dateFormat.format(d.toLocal());

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(walletControllerProvider),
            ),
        data:
            (summary) => RefreshIndicator(
              onRefresh: ref.read(walletControllerProvider.notifier).refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(summary: summary),
                  const SizedBox(height: 12),
                  _BankAccountCard(summary: summary),
                  const SizedBox(height: 24),
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const _LedgerList(),
                ],
              ),
            ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWithdraw =
        !summary.withdrawalBlocked &&
        summary.bankAccount != null &&
        summary.balancePaise >= summary.minWithdrawalPaise &&
        summary.balancePaise > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available balance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              formatPaise(summary.balancePaise),
              key: const Key('wallet-balance'),
              style: theme.textTheme.headlineMedium,
            ),
            if (summary.pendingWithdrawalPaise > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${formatPaise(summary.pendingWithdrawalPaise)} payout in progress',
                key: const Key('wallet-pending'),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Minimum withdrawal ${formatPaise(summary.minWithdrawalPaise)}',
              style: theme.textTheme.bodySmall,
            ),
            if (summary.withdrawalBlocked) ...[
              const SizedBox(height: 8),
              Text(
                WalletValidators.withdrawalBlockedMessage,
                key: const Key('wallet-blocked'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('withdraw-button'),
                    onPressed:
                        canWithdraw
                            ? () => showWithdrawSheet(context, summary)
                            : null,
                    child: const Text('Withdraw'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('payout-history-button'),
                    onPressed: () => context.push(AppRoutes.walletPayouts),
                    child: const Text('Payout history'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final bank = summary.bankAccount;
    return Card(
      child: ListTile(
        key: const Key('bank-account-tile'),
        leading: const Icon(Icons.account_balance_outlined),
        title: Text(bank == null ? 'Add bank account' : bank.holderName),
        subtitle: Text(
          bank == null
              ? 'Required to withdraw your earnings'
              : '${bank.maskedNumber} · ${bank.ifsc}',
        ),
        trailing: Text(bank == null ? 'Add' : 'Edit'),
        onTap: () => context.push(AppRoutes.walletBank),
      ),
    );
  }
}

class _LedgerList extends ConsumerWidget {
  const _LedgerList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerControllerProvider);
    return ledger.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => SizedBox(
            height: 200,
            child: ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(ledgerControllerProvider),
            ),
          ),
      data: (paged) {
        if (paged.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No transactions yet. Sales of your drawings show up here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final notifier = ref.read(ledgerControllerProvider.notifier);
        return Column(
          children: [
            for (final entry in paged.items) LedgerTile(entry: entry),
            if (paged.hasMore)
              LoadMoreSentinel(
                key: ValueKey('ledger-more-${paged.items.length}'),
                loading: paged.isLoadingMore,
                errorMessage: paged.loadMoreError?.message,
                onLoadMore: notifier.loadMore,
                onRetry: notifier.retryLoadMore,
              ),
          ],
        );
      },
    );
  }
}

class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.entry});
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        entry.isCredit ? Colors.green.shade700 : theme.colorScheme.error;
    final sign = entry.isCredit ? '+' : '−';
    return ListTile(
      key: ValueKey('ledger-${entry.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.isCredit ? Icons.south_west : Icons.north_east,
        color: color,
      ),
      title: Text(entry.title),
      subtitle: Text(
        '${entry.entryType.label} · ${formatWalletDate(entry.createdAt)}',
      ),
      trailing: Text(
        '$sign${formatPaise(entry.amountPaise.abs())}',
        style: theme.textTheme.titleSmall?.copyWith(color: color),
      ),
    );
  }
}
