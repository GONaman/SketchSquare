import '../../../core/network/api_exception.dart';
import '../../upload/domain/money.dart';
import 'wallet_models.dart';

/// Pure client-side checks; the server re-validates everything.
abstract final class WalletValidators {
  static final _ifsc = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final _holder = RegExp(r"^[A-Za-z][A-Za-z .'-]*$");
  static final _digits = RegExp(r'^\d+$');

  static String normalizeIfsc(String v) => v.trim().toUpperCase();

  static String normalizeAccountNumber(String v) =>
      v.replaceAll(RegExp(r'[\s-]'), '');

  static String? holderName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter the account holder name';
    if (t.length < 2 || t.length > 100) {
      return 'Name must be 2–100 characters';
    }
    if (!_holder.hasMatch(t)) return 'Use letters, spaces and . \' - only';
    return null;
  }

  static String? ifsc(String? v) {
    final t = normalizeIfsc(v ?? '');
    if (t.isEmpty) return 'Enter the IFSC code';
    if (!_ifsc.hasMatch(t)) {
      return 'IFSC is 11 characters, e.g. HDFC0001234';
    }
    return null;
  }

  static String? accountNumber(String? v) {
    final t = normalizeAccountNumber(v ?? '');
    if (t.isEmpty) return 'Enter the account number';
    if (!_digits.hasMatch(t)) return 'Digits only';
    if (t.length < 9 || t.length > 18) return 'Must be 9–18 digits';
    return null;
  }

  /// Shown wherever a negative balance (e.g. after a refunded sale) blocks
  /// withdrawals; the server code is `WITHDRAWAL_BLOCKED`.
  static const withdrawalBlockedMessage =
      'Withdrawals are blocked while your balance is negative, for example '
      'after a refunded sale. New sales will bring it back up. '
      'Contact support if you need help.';

  /// [input] is a rupee string. The wallet balance reported by the server is
  /// the withdrawable amount (pending payouts are already deducted from it).
  static String? withdrawalAmount(String? input, WalletSummary wallet) {
    if (wallet.withdrawalBlocked) {
      return withdrawalBlockedMessage;
    }
    if (wallet.bankAccount == null) return 'Add a bank account first';
    final paise = parseRupeesToPaise(input ?? '');
    if (paise == null || paise <= 0) {
      return 'Enter a valid amount, up to 2 decimals';
    }
    if (paise < wallet.minWithdrawalPaise) {
      return 'Minimum withdrawal is ${formatPaise(wallet.minWithdrawalPaise)}';
    }
    if (paise > wallet.balancePaise) {
      return 'Amount exceeds your balance of ${formatPaise(wallet.balancePaise)}';
    }
    return null;
  }

  /// Friendly text for the wallet-specific server errors.
  static String messageFor(ApiException e) => switch (e.code) {
    ApiErrorCodes.insufficientBalance =>
      'Your balance is too low for this withdrawal.',
    ApiErrorCodes.belowMinWithdrawal =>
      'The amount is below the minimum withdrawal.',
    ApiErrorCodes.withdrawalBlocked => withdrawalBlockedMessage,
    _ => e.message,
  };
}
