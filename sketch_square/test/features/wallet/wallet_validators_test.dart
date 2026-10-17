import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/wallet/domain/wallet_models.dart';
import 'package:sketch_square/features/wallet/domain/wallet_validators.dart';

import 'fakes.dart';

void main() {
  group('holderName', () {
    test('accepts normal names', () {
      expect(WalletValidators.holderName('Asha Rao'), isNull);
      expect(WalletValidators.holderName("D'Souza-Pinto Jr."), isNull);
    });
    test('rejects empty, short, digits', () {
      expect(WalletValidators.holderName(''), isNotNull);
      expect(WalletValidators.holderName(' A '), isNotNull);
      expect(WalletValidators.holderName('Asha 2'), isNotNull);
      expect(WalletValidators.holderName('A' * 101), isNotNull);
    });
  });

  group('ifsc', () {
    test('accepts valid codes case-insensitively', () {
      expect(WalletValidators.ifsc('HDFC0001234'), isNull);
      expect(WalletValidators.ifsc(' sbin0ab12c3 '), isNull);
    });
    test('rejects malformed codes', () {
      expect(WalletValidators.ifsc(''), isNotNull);
      expect(WalletValidators.ifsc('HDFC1001234'), isNotNull); // 5th must be 0
      expect(WalletValidators.ifsc('HDF00001234'), isNotNull);
      expect(WalletValidators.ifsc('HDFC000123'), isNotNull); // too short
    });
    test('normalizes to uppercase', () {
      expect(WalletValidators.normalizeIfsc(' hdfc0001234 '), 'HDFC0001234');
    });
  });

  group('accountNumber', () {
    test('accepts 9–18 digits, ignoring spaces and dashes', () {
      expect(WalletValidators.accountNumber('123456789'), isNull);
      expect(WalletValidators.accountNumber('1234 5678 9012 3456'), isNull);
      expect(WalletValidators.accountNumber('1' * 18), isNull);
      expect(
        WalletValidators.normalizeAccountNumber('1234-5678 9'),
        '123456789',
      );
    });
    test('rejects short, long, letters, empty', () {
      expect(WalletValidators.accountNumber('12345678'), isNotNull);
      expect(WalletValidators.accountNumber('1' * 19), isNotNull);
      expect(WalletValidators.accountNumber('12345678a'), isNotNull);
      expect(WalletValidators.accountNumber(''), isNotNull);
    });
  });

  group('withdrawalAmount', () {
    final wallet = fakeWallet(balancePaise: 250000, minWithdrawalPaise: 50000);

    test('accepts amounts between minimum and balance inclusive', () {
      expect(WalletValidators.withdrawalAmount('500', wallet), isNull);
      expect(WalletValidators.withdrawalAmount('2,500', wallet), isNull);
      expect(WalletValidators.withdrawalAmount('1234.50', wallet), isNull);
    });

    test('rejects non-numeric, zero and over-precise input', () {
      for (final bad in ['', 'abc', '0', '-5', '10.123']) {
        expect(
          WalletValidators.withdrawalAmount(bad, wallet),
          isNotNull,
          reason: bad,
        );
      }
    });

    test('rejects below minimum', () {
      expect(
        WalletValidators.withdrawalAmount('499.99', wallet),
        contains('Minimum'),
      );
    });

    test('rejects above balance', () {
      expect(
        WalletValidators.withdrawalAmount('2500.01', wallet),
        contains('exceeds'),
      );
    });

    test('rejects when blocked or without a bank account', () {
      expect(
        WalletValidators.withdrawalAmount(
          '500',
          fakeWallet(withdrawalBlocked: true),
        ),
        contains('blocked'),
      );
      expect(
        WalletValidators.withdrawalAmount('500', fakeWallet(bankAccount: null)),
        contains('bank account'),
      );
    });
  });

  group('messageFor', () {
    test('maps wallet error codes to friendly text', () {
      String msg(String code) => WalletValidators.messageFor(
        ApiException(code: code, message: 'server text'),
      );
      expect(msg(ApiErrorCodes.insufficientBalance), contains('too low'));
      expect(msg(ApiErrorCodes.belowMinWithdrawal), contains('minimum'));
      expect(msg(ApiErrorCodes.withdrawalBlocked), contains('blocked'));
      expect(msg(ApiErrorCodes.internal), 'server text');
    });
  });

  group('models', () {
    test('unknown entry type falls back to a generic label', () {
      final e = LedgerEntry.fromJson({
        'id': 'l1',
        'entryType': 'SOMETHING_NEW',
        'amountPaise': -500,
        'description': null,
        'referenceId': null,
        'createdAt': '2026-03-04T10:00:00.000Z',
      });
      expect(e.entryType, LedgerEntryType.other);
      expect(e.title, 'Transaction');
      expect(e.isCredit, isFalse);
    });

    test('bank account is masked', () {
      expect(fakeWallet().bankAccount!.maskedNumber, 'XXXX XXXX 6789');
    });
  });
}
