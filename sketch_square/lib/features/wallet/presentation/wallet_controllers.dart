import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../data/wallet_providers.dart';
import '../domain/wallet_models.dart';

part 'wallet_controllers.g.dart';

/// Balance, limits and the payout bank account (`GET /wallet`).
@Riverpod(keepAlive: true)
class WalletController extends _$WalletController {
  @override
  Future<WalletSummary> build() {
    ref.watch(currentUserIdProvider);
    return ref.watch(walletRepositoryProvider).summary();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).summary(),
    );
    ref.invalidate(ledgerControllerProvider);
    ref.invalidate(withdrawalsControllerProvider);
  }

  /// Throws [ApiException] on failure so the form can show it inline.
  Future<void> saveBankAccount({
    required String holderName,
    required String ifsc,
    required String accountNumber,
  }) async {
    final saved = await ref
        .read(walletRepositoryProvider)
        .saveBankAccount(
          holderName: holderName,
          ifsc: ifsc,
          accountNumber: accountNumber,
        );
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(bankAccount: saved));
    } else {
      ref.invalidateSelf();
    }
  }

  /// Requests a payout, then reloads balance, ledger and payout history.
  /// Throws [ApiException] on failure.
  Future<Withdrawal> withdraw(int amountPaise) async {
    final withdrawal = await ref
        .read(walletRepositoryProvider)
        .requestWithdrawal(amountPaise);
    await refresh();
    return withdrawal;
  }
}

/// Wallet transactions, newest first.
@Riverpod(keepAlive: true)
class LedgerController extends _$LedgerController {
  @override
  Future<PagedState<LedgerEntry>> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(walletRepositoryProvider).ledger();
    return PagedState.fromPage(page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(walletRepositoryProvider)
          .ledger(cursor: current.nextCursor);
      state = AsyncData(current.appended(page, (e) => e.id));
    } catch (e) {
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }

  void retryLoadMore() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      PagedState(items: current.items, nextCursor: current.nextCursor),
    );
    loadMore();
  }
}

/// Payout history (`GET /wallet/withdrawals`), newest first.
@Riverpod(keepAlive: true)
class WithdrawalsController extends _$WithdrawalsController {
  @override
  Future<PagedState<Withdrawal>> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(walletRepositoryProvider).withdrawals();
    return PagedState.fromPage(page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(walletRepositoryProvider)
          .withdrawals(cursor: current.nextCursor);
      state = AsyncData(current.appended(page, (w) => w.id));
    } catch (e) {
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }

  void retryLoadMore() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      PagedState(items: current.items, nextCursor: current.nextCursor),
    );
    loadMore();
  }
}
