import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_validators.dart';
import 'wallet_controllers.dart';
import 'withdraw_sheet.dart';

final _dateFormat = DateFormat('d MMM y, h:mm a');
final _timeFormat = DateFormat('h:mm a');
final _dayFormat = DateFormat('d MMM y');

String formatWalletDate(DateTime d) => _dateFormat.format(d.toLocal());

/// "Today", "Yesterday" or a calendar date, for ledger group headers.
String walletDayLabel(DateTime d, {DateTime? now}) {
  final local = d.toLocal();
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(local)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return _dayFormat.format(local);
}

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: wallet.when(
        loading: () => const ListRowSkeleton(count: 4),
        error:
            (e, _) => ErrorState(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(walletControllerProvider),
            ),
        data:
            (summary) => RefreshIndicator(
              onRefresh: ref.read(walletControllerProvider.notifier).refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  AppSpacing.xxl,
                ),
                children: [
                  _BalanceCard(summary: summary),
                  if (summary.withdrawalBlocked) ...[
                    const SizedBox(height: AppSpacing.md),
                    FormErrorBanner(
                      WalletValidators.withdrawalBlockedMessage,
                      key: const Key('wallet-blocked'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _BankAccountCard(summary: summary),
                  const SizedBox(height: AppSpacing.sm),
                  const _SectionLabel('Transactions'),
                  const _LedgerList(),
                ],
              ),
            ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
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
    final sem = AppSemanticColors.of(context);
    final canWithdraw =
        !summary.withdrawalBlocked &&
        summary.bankAccount != null &&
        summary.balancePaise >= summary.minWithdrawalPaise &&
        summary.balancePaise > 0;
    final muted = sem.onInk.withValues(alpha: 0.72);
    return InkHeroCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Available balance',
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatPaise(summary.balancePaise),
              key: const Key('wallet-balance'),
              style:
                  theme.textTheme.displaySmall
                      ?.copyWith(color: sem.onInk, fontWeight: FontWeight.w700)
                      .tabular,
            ),
          ),
          if (summary.pendingWithdrawalPaise > 0) ...[
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: sem.onInk),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        '${formatPaise(summary.pendingWithdrawalPaise)} payout in progress',
                        key: const Key('wallet-pending'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: sem.onInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('withdraw-button'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Colors.white,
                    foregroundColor: sem.ink,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.16,
                    ),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  onPressed:
                      canWithdraw
                          ? () => showWithdrawSheet(context, summary)
                          : null,
                  icon: const Icon(Icons.north_east_rounded, size: 18),
                  label: const Text('Withdraw'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  key: const Key('payout-history-button'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: sem.onInk,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.walletPayouts),
                  child: const Text('Payout history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Minimum withdrawal ${formatPaise(summary.minWithdrawalPaise)}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bank = summary.bankAccount;
    return AppCard(
      key: const Key('bank-account-tile'),
      onTap: () => context.push(AppRoutes.walletBank),
      style: bank == null ? AppCardStyle.tonal : AppCardStyle.elevated,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.account_balance_outlined,
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
                  bank == null ? 'Add bank account' : bank.holderName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  bank == null
                      ? 'Required to withdraw your earnings'
                      : '${bank.maskedNumber} · ${bank.ifsc}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            bank == null ? 'Add' : 'Edit',
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
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
      loading: () => const ListRowSkeleton(count: 3),
      error:
          (e, _) => SizedBox(
            height: 240,
            child: ErrorState(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(ledgerControllerProvider),
            ),
          ),
      data: (paged) {
        if (paged.items.isEmpty) {
          return const EmptyState(
            compact: true,
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            message: 'Sales of your drawings show up here.',
          );
        }
        final notifier = ref.read(ledgerControllerProvider.notifier);
        final groups = <String, List<LedgerEntry>>{};
        for (final entry in paged.items) {
          groups
              .putIfAbsent(walletDayLabel(entry.createdAt), () => [])
              .add(entry);
        }
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Text(
                  g.key,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < g.value.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 72,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      LedgerTile(entry: g.value[i]),
                    ],
                  ],
                ),
              ),
            ],
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
    final sem = AppSemanticColors.of(context);
    final scheme = theme.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final credit = entry.isCredit;
    final tint = credit ? sem.successContainer : scheme.errorContainer;
    final iconColor =
        credit
            ? (dark ? sem.success : const Color(0xFF0B4A2F))
            : scheme.onErrorContainer;
    final amountColor =
        credit ? (dark ? sem.success : const Color(0xFF0B6B43)) : scheme.error;
    final sign = credit ? '+' : '−';
    return Padding(
      key: ValueKey('ledger-${entry.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(
                credit ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.entryType.label} · ${_timeFormat.format(entry.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign${formatPaise(entry.amountPaise.abs())}',
            style:
                theme.textTheme.titleSmall
                    ?.copyWith(color: amountColor)
                    .tabular,
          ),
        ],
      ),
    );
  }
}
