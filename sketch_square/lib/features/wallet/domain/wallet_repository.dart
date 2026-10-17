import '../../../core/network/cursor_page.dart';
import 'wallet_models.dart';

abstract interface class WalletRepository {
  Future<WalletSummary> summary();

  Future<CursorPage<LedgerEntry>> ledger({String? cursor, int? limit});

  /// Creates or replaces the payout bank account.
  Future<BankAccountInfo> saveBankAccount({
    required String holderName,
    required String ifsc,
    required String accountNumber,
  });

  Future<Withdrawal> requestWithdrawal(int amountPaise);

  Future<CursorPage<Withdrawal>> withdrawals({String? cursor, int? limit});
}
