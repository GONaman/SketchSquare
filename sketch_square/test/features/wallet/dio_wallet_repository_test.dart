import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/wallet/data/dio_wallet_repository.dart';
import 'package:sketch_square/features/wallet/domain/wallet_models.dart';

import '../../helpers/scripted_adapter.dart';

void main() {
  Dio dio(ScriptedAdapter a) =>
      Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = a;

  test('summary parses balance and bank account', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'balancePaise': 250000,
        'pendingWithdrawalPaise': 100000,
        'minWithdrawalPaise': 50000,
        'withdrawalBlocked': false,
        'bankAccount': {
          'holderName': 'Asha Rao',
          'ifsc': 'HDFC0001234',
          'accountNumberLast4': '6789',
        },
      }),
    );
    final s = await DioWalletRepository(dio(a)).summary();

    expect(a.requests.single.method, 'GET');
    expect(a.requests.single.path, '/wallet');
    expect(s.balancePaise, 250000);
    expect(s.pendingWithdrawalPaise, 100000);
    expect(s.bankAccount!.accountNumberLast4, '6789');
  });

  test('summary tolerates a missing bank account', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'balancePaise': 0,
        'pendingWithdrawalPaise': 0,
        'minWithdrawalPaise': 50000,
        'withdrawalBlocked': true,
        'bankAccount': null,
      }),
    );
    final s = await DioWalletRepository(dio(a)).summary();
    expect(s.bankAccount, isNull);
    expect(s.withdrawalBlocked, isTrue);
  });

  test('ledger sends cursor/limit and parses the page', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'items': [
          {
            'id': 'l1',
            'entryType': 'SALE',
            'amountPaise': 44910,
            'description': 'Modern Villa',
            'referenceId': 'p1',
            'createdAt': '2026-03-04T10:00:00.000Z',
          },
        ],
        'nextCursor': 'c2',
      }),
    );
    final page = await DioWalletRepository(
      dio(a),
    ).ledger(cursor: 'c1', limit: 10);

    expect(a.requests.single.path, '/wallet/ledger');
    expect(a.requests.single.queryParameters, {'cursor': 'c1', 'limit': 10});
    expect(page.items.single.entryType, LedgerEntryType.sale);
    expect(page.nextCursor, 'c2');
  });

  test('ledger omits paging params on the first page', () async {
    final a = ScriptedAdapter((_) => jsonResponse({'items': []}));
    await DioWalletRepository(dio(a)).ledger();
    expect(a.requests.single.queryParameters, isEmpty);
  });

  test('saveBankAccount POSTs the full details', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'holderName': 'Asha Rao',
        'ifsc': 'HDFC0001234',
        'accountNumberLast4': '6789',
      }),
    );
    final info = await DioWalletRepository(dio(a)).saveBankAccount(
      holderName: 'Asha Rao',
      ifsc: 'HDFC0001234',
      accountNumber: '123456789',
    );

    expect(a.requests.single.method, 'POST');
    expect(a.requests.single.path, '/wallet/bank-account');
    expect(a.requests.single.data, {
      'holderName': 'Asha Rao',
      'ifsc': 'HDFC0001234',
      'accountNumber': '123456789',
    });
    expect(info.accountNumberLast4, '6789');
  });

  test('requestWithdrawal POSTs paise and parses the 201 body', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'id': 'w1',
        'amountPaise': 100000,
        'status': 'REQUESTED',
        'createdAt': '2026-03-04T10:00:00.000Z',
        'updatedAt': '2026-03-04T10:00:00.000Z',
      }, 201),
    );
    final w = await DioWalletRepository(dio(a)).requestWithdrawal(100000);

    expect(a.requests.single.path, '/wallet/withdrawals');
    expect(a.requests.single.data, {'amountPaise': 100000});
    expect(w.status, WithdrawalStatus.requested);
  });

  test('requestWithdrawal surfaces wallet error codes', () async {
    final a = ScriptedAdapter(
      (_) => errorResponse(409, 'INSUFFICIENT_BALANCE', 'Not enough'),
    );
    await expectLater(
      DioWalletRepository(dio(a)).requestWithdrawal(1),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCodes.insufficientBalance,
        ),
      ),
    );
  });

  test('withdrawals lists the payout history', () async {
    final a = ScriptedAdapter(
      (_) => jsonResponse({
        'items': [
          {
            'id': 'w1',
            'amountPaise': 100000,
            'status': 'PAID',
            'createdAt': '2026-03-04T10:00:00.000Z',
            'updatedAt': '2026-03-05T10:00:00.000Z',
          },
        ],
        'nextCursor': null,
      }),
    );
    final page = await DioWalletRepository(dio(a)).withdrawals(cursor: 'x');

    expect(a.requests.single.path, '/wallet/withdrawals');
    expect(a.requests.single.queryParameters, {'cursor': 'x'});
    expect(page.items.single.status, WithdrawalStatus.paid);
    expect(page.hasMore, isFalse);
  });
}
