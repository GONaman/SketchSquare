import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/wallet/data/wallet_providers.dart';
import 'package:sketch_square/features/wallet/presentation/wallet_controllers.dart';

import '../purchases/fakes.dart' show offline;
import 'fakes.dart';

ProviderContainer _container(FakeWalletRepository repo) => ProviderContainer(
  overrides: [
    walletRepositoryProvider.overrideWithValue(repo),
    currentUserProvider.overrideWithValue(stubUser),
  ],
);

void main() {
  group('ledger pagination', () {
    final five = [for (var i = 1; i <= 5; i++) fakeLedgerEntry(i)];

    test('loads page by page and stops at the end', () async {
      final repo = FakeWalletRepository(ledger: five);
      final c = _container(repo);
      addTearDown(c.dispose);

      var s = await c.read(ledgerControllerProvider.future);
      expect(s.items.map((e) => e.id), ['l1', 'l2']);
      expect(s.canLoadMore, isTrue);

      final n = c.read(ledgerControllerProvider.notifier);
      await n.loadMore();
      await n.loadMore();
      s = c.read(ledgerControllerProvider).requireValue;
      expect(s.items.length, 5);
      expect(s.hasMore, isFalse);

      await n.loadMore();
      expect(repo.ledgerCursors, [null, '2', '4']);
    });

    test('a failed page keeps items and retry continues', () async {
      final repo = FakeWalletRepository(ledger: five);
      final c = _container(repo);
      addTearDown(c.dispose);
      await c.read(ledgerControllerProvider.future);
      final n = c.read(ledgerControllerProvider.notifier);

      repo.ledgerError = offline;
      await n.loadMore();
      var s = c.read(ledgerControllerProvider).requireValue;
      expect(s.items.length, 2);
      expect(s.loadMoreError?.code, ApiErrorCodes.network);
      expect(s.canLoadMore, isFalse);

      repo.ledgerError = null;
      n.retryLoadMore();
      await Future<void>.delayed(Duration.zero);
      s = c.read(ledgerControllerProvider).requireValue;
      expect(s.items.length, 4);
      expect(s.loadMoreError, isNull);
    });

    test('overlapping pages never duplicate entries', () async {
      final repo = FakeWalletRepository(ledger: five);
      final c = _container(repo);
      addTearDown(c.dispose);
      await c.read(ledgerControllerProvider.future);

      // A new sale shifts the window by one.
      repo.ledgerEntries = [fakeLedgerEntry(0), ...five];
      await c.read(ledgerControllerProvider.notifier).loadMore();
      final ids =
          c
              .read(ledgerControllerProvider)
              .requireValue
              .items
              .map((e) => e.id)
              .toList();
      expect(ids, ['l1', 'l2', 'l3']);
    });
  });

  group('payout history pagination', () {
    test('appends pages and reports the end', () async {
      final repo = FakeWalletRepository(
        withdrawals: [for (var i = 1; i <= 3; i++) fakeWithdrawal(i)],
      );
      final c = _container(repo);
      addTearDown(c.dispose);

      var s = await c.read(withdrawalsControllerProvider.future);
      expect(s.items.length, 2);
      await c.read(withdrawalsControllerProvider.notifier).loadMore();
      s = c.read(withdrawalsControllerProvider).requireValue;
      expect(s.items.map((w) => w.id), ['w1', 'w2', 'w3']);
      expect(s.hasMore, isFalse);
    });
  });

  group('wallet actions', () {
    test('withdraw refreshes balance and history', () async {
      final repo = FakeWalletRepository(
        wallet: fakeWallet(balancePaise: 250000),
        ledger: [fakeLedgerEntry(1)],
      );
      final c = _container(repo);
      addTearDown(c.dispose);
      await c.read(walletControllerProvider.future);
      await c.read(withdrawalsControllerProvider.future);

      await c.read(walletControllerProvider.notifier).withdraw(100000);

      final w = c.read(walletControllerProvider).requireValue;
      expect(repo.requestedAmounts, [100000]);
      expect(w.balancePaise, 150000);
      expect(w.pendingWithdrawalPaise, 100000);
      final payouts = await c.read(withdrawalsControllerProvider.future);
      expect(payouts.items.first.amountPaise, 100000);
    });

    test('a rejected withdrawal rethrows and keeps the balance', () async {
      final repo =
          FakeWalletRepository()
            ..withdrawError = const ApiException(
              code: ApiErrorCodes.insufficientBalance,
              message: 'no',
            );
      final c = _container(repo);
      addTearDown(c.dispose);
      await c.read(walletControllerProvider.future);

      await expectLater(
        c.read(walletControllerProvider.notifier).withdraw(100000),
        throwsA(isA<ApiException>()),
      );
      expect(
        c.read(walletControllerProvider).requireValue.balancePaise,
        250000,
      );
    });

    test('saveBankAccount updates the summary in place', () async {
      final repo = FakeWalletRepository(wallet: fakeWallet(bankAccount: null));
      final c = _container(repo);
      addTearDown(c.dispose);
      await c.read(walletControllerProvider.future);

      await c
          .read(walletControllerProvider.notifier)
          .saveBankAccount(
            holderName: 'Asha Rao',
            ifsc: 'HDFC0001234',
            accountNumber: '123456789',
          );

      final bank = c.read(walletControllerProvider).requireValue.bankAccount;
      expect(bank?.accountNumberLast4, '6789');
      expect(repo.summaryCalls, 1);
    });
  });
}
