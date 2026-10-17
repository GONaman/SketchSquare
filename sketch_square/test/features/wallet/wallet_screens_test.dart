import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/wallet/data/wallet_providers.dart';
import 'package:sketch_square/features/wallet/domain/wallet_models.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

void main() {
  late FakeWalletRepository repo;

  setUp(() {
    repo = FakeWalletRepository(
      ledger: [
        fakeLedgerEntry(1, description: 'Modern Villa'),
        fakeLedgerEntry(
          2,
          amountPaise: -100000,
          type: LedgerEntryType.withdrawal,
          description: 'Payout',
        ),
        fakeLedgerEntry(3, description: 'Duplex Plan'),
      ],
      withdrawals: [
        fakeWithdrawal(1, status: WithdrawalStatus.paid),
        fakeWithdrawal(2, amountPaise: 75000),
        fakeWithdrawal(3, status: WithdrawalStatus.failed),
      ],
    );
  });

  Future<void> open(
    WidgetTester tester, [
    String path = AppRoutes.wallet,
  ]) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await pumpApp(
      tester,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: stubUser),
        ),
        walletRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    router.push(path);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  group('wallet screen', () {
    testWidgets('shows balance, pending payout, bank account and ledger', (
      tester,
    ) async {
      repo.wallet = fakeWallet(pendingWithdrawalPaise: 75000);
      await open(tester);

      expect(find.byKey(const Key('wallet-balance')), findsOneWidget);
      expect(find.text('₹2,500'), findsOneWidget);
      expect(find.textContaining('₹750 payout in progress'), findsOneWidget);
      expect(find.text('Asha Rao'), findsOneWidget);
      expect(find.textContaining('XXXX XXXX 6789'), findsOneWidget);
      expect(find.text('Modern Villa'), findsOneWidget);
      expect(find.text('+₹449.10'), findsWidgets);
      expect(find.text('−₹1,000'), findsOneWidget);
    });

    testWidgets('ledger loads the next page when scrolled to the end', (
      tester,
    ) async {
      await open(tester);

      // Page size is 2; the sentinel fetches the third entry.
      expect(find.text('Duplex Plan'), findsOneWidget);
      expect(repo.ledgerCursors, [null, '2']);
    });

    testWidgets('empty ledger shows a hint', (tester) async {
      repo.ledgerEntries = [];
      await open(tester);
      expect(find.textContaining('No transactions yet'), findsOneWidget);
    });

    testWidgets('withdraw is disabled without a bank account', (tester) async {
      repo.wallet = fakeWallet(bankAccount: null);
      await open(tester);

      expect(find.text('Add bank account'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('withdraw-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('blocked accounts see a notice and cannot withdraw', (
      tester,
    ) async {
      repo.wallet = fakeWallet(withdrawalBlocked: true);
      await open(tester);

      expect(find.byKey(const Key('wallet-blocked')), findsOneWidget);
      expect(find.textContaining('balance is negative'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('withdraw-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('load failure offers retry', (tester) async {
      repo.summaryError = offlineError;
      await open(tester);
      expect(find.text('No connection'), findsOneWidget);

      repo.summaryError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet-balance')), findsOneWidget);
    });
  });

  group('withdraw sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('withdraw-button')));
      await tester.pumpAndSettle();
    }

    testWidgets('validates amount before calling the API', (tester) async {
      await openSheet(tester);

      await enter(tester, 'withdraw-amount', '100');
      await tester.tap(find.byKey(const Key('withdraw-submit')));
      await tester.pump();
      expect(find.textContaining('Minimum withdrawal ₹500'), findsWidgets);

      await enter(tester, 'withdraw-amount', '9999');
      await tester.tap(find.byKey(const Key('withdraw-submit')));
      await tester.pump();
      expect(find.textContaining('exceeds your balance'), findsOneWidget);
      expect(repo.requestedAmounts, isEmpty);
    });

    testWidgets('requests the amount in paise and updates the balance', (
      tester,
    ) async {
      await openSheet(tester);

      await enter(tester, 'withdraw-amount', '1,000.50');
      await tester.tap(find.byKey(const Key('withdraw-submit')));
      await tester.pumpAndSettle();

      expect(repo.requestedAmounts, [100050]);
      expect(find.byKey(const Key('withdraw-submit')), findsNothing);
      expect(find.textContaining('requested'), findsOneWidget);
      expect(find.textContaining('₹1,499.50'), findsOneWidget);
      expect(
        find.textContaining('₹1,000.50 payout in progress'),
        findsOneWidget,
      );
    });

    testWidgets('shows the server error and keeps the sheet open', (
      tester,
    ) async {
      repo.withdrawError = const ApiException(
        code: ApiErrorCodes.withdrawalBlocked,
        message: 'blocked',
      );
      await openSheet(tester);

      await enter(tester, 'withdraw-amount', '600');
      await tester.tap(find.byKey(const Key('withdraw-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('balance is negative'), findsOneWidget);
      expect(find.byKey(const Key('withdraw-submit')), findsOneWidget);
    });
  });

  group('bank account form', () {
    testWidgets('validates every field', (tester) async {
      repo.wallet = fakeWallet(bankAccount: null);
      await open(tester, AppRoutes.walletBank);

      await tester.tap(find.byKey(const Key('bank-save')));
      await tester.pump();
      expect(find.text('Enter the account holder name'), findsOneWidget);
      expect(find.text('Enter the IFSC code'), findsOneWidget);
      expect(find.text('Enter the account number'), findsOneWidget);
      expect(repo.savedBankAccounts, isEmpty);

      await enter(tester, 'field-holder', 'Asha Rao');
      await enter(tester, 'field-ifsc', 'BAD');
      await enter(tester, 'field-account', '123456789');
      await enter(tester, 'field-account-confirm', '123456780');
      await tester.tap(find.byKey(const Key('bank-save')));
      await tester.pump();
      expect(find.textContaining('IFSC is 11 characters'), findsOneWidget);
      expect(find.text('Account numbers do not match'), findsOneWidget);
    });

    testWidgets('saves normalised details and returns to the wallet', (
      tester,
    ) async {
      repo.wallet = fakeWallet(bankAccount: null);
      await open(tester);
      await tester.tap(find.byKey(const Key('bank-account-tile')));
      await tester.pumpAndSettle();

      await enter(tester, 'field-holder', ' Asha Rao ');
      await enter(tester, 'field-ifsc', 'hdfc0001234');
      await enter(tester, 'field-account', '1234 5678 9');
      await enter(tester, 'field-account-confirm', '123456789');
      await tester.tap(find.byKey(const Key('bank-save')));
      await tester.pumpAndSettle();

      expect(repo.savedBankAccounts.single, {
        'holderName': 'Asha Rao',
        'ifsc': 'HDFC0001234',
        'accountNumber': '123456789',
      });
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.textContaining('XXXX XXXX 6789'), findsOneWidget);
    });

    testWidgets('prefills holder and IFSC when editing', (tester) async {
      await open(tester, AppRoutes.walletBank);
      expect(find.text('Edit bank account'), findsOneWidget);
      expect(find.text('HDFC0001234'), findsOneWidget);
      expect(find.textContaining('Currently XXXX XXXX 6789'), findsOneWidget);
    });

    testWidgets('server validation errors land on the field', (tester) async {
      repo.bankError = const ApiException(
        code: ApiErrorCodes.validation,
        message: 'Invalid',
        details: {
          'fields': {'ifsc': 'Unknown bank branch'},
        },
      );
      repo.wallet = fakeWallet(bankAccount: null);
      await open(tester, AppRoutes.walletBank);

      await enter(tester, 'field-holder', 'Asha Rao');
      await enter(tester, 'field-ifsc', 'HDFC0001234');
      await enter(tester, 'field-account', '123456789');
      await enter(tester, 'field-account-confirm', '123456789');
      await tester.tap(find.byKey(const Key('bank-save')));
      await tester.pumpAndSettle();

      expect(find.text('Unknown bank branch'), findsOneWidget);
    });
  });

  group('payout history', () {
    testWidgets('lists withdrawals with status and paginates', (tester) async {
      await open(tester, AppRoutes.walletPayouts);

      expect(find.text('Payout history'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('₹750'), findsOneWidget);
      // Third page item arrives through the sentinel.
      expect(find.text('Failed'), findsOneWidget);
      expect(repo.withdrawalCursors, [null, '2']);
    });

    testWidgets('empty state', (tester) async {
      repo.payouts = [];
      await open(tester, AppRoutes.walletPayouts);
      expect(find.text('No payouts yet'), findsOneWidget);
    });

    testWidgets('reachable from the wallet screen', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('payout-history-button')));
      await tester.pumpAndSettle();
      expect(find.text('Payout history'), findsOneWidget);
    });
  });
}

const offlineError = ApiException(
  code: ApiErrorCodes.network,
  message: 'No connection',
);
