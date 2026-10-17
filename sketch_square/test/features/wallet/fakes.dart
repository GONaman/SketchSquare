import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/wallet/domain/wallet_models.dart';
import 'package:sketch_square/features/wallet/domain/wallet_repository.dart';

WalletSummary fakeWallet({
  int balancePaise = 250000,
  int pendingWithdrawalPaise = 0,
  int minWithdrawalPaise = 50000,
  bool withdrawalBlocked = false,
  BankAccountInfo? bankAccount = const BankAccountInfo(
    holderName: 'Asha Rao',
    ifsc: 'HDFC0001234',
    accountNumberLast4: '6789',
  ),
}) => WalletSummary(
  balancePaise: balancePaise,
  pendingWithdrawalPaise: pendingWithdrawalPaise,
  minWithdrawalPaise: minWithdrawalPaise,
  withdrawalBlocked: withdrawalBlocked,
  bankAccount: bankAccount,
);

LedgerEntry fakeLedgerEntry(
  int n, {
  int amountPaise = 44910,
  LedgerEntryType type = LedgerEntryType.sale,
  String? description,
}) => LedgerEntry(
  id: 'l$n',
  entryType: type,
  amountPaise: amountPaise,
  description: description ?? 'Sale #$n',
  createdAt: DateTime.utc(2026, 3, 4, 10, n),
);

Withdrawal fakeWithdrawal(
  int n, {
  int amountPaise = 100000,
  WithdrawalStatus status = WithdrawalStatus.requested,
}) => Withdrawal(
  id: 'w$n',
  amountPaise: amountPaise,
  status: status,
  createdAt: DateTime.utc(2026, 3, 4, 10, n),
  updatedAt: DateTime.utc(2026, 3, 4, 10, n),
);

class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({
    WalletSummary? wallet,
    List<LedgerEntry>? ledger,
    List<Withdrawal>? withdrawals,
    this.pageSize = 2,
  }) : wallet = wallet ?? fakeWallet(),
       ledgerEntries = ledger ?? [],
       payouts = withdrawals ?? [];

  WalletSummary wallet;
  List<LedgerEntry> ledgerEntries;
  List<Withdrawal> payouts;
  int pageSize;

  ApiException? summaryError;
  ApiException? ledgerError;
  ApiException? withdrawError;
  ApiException? bankError;

  final ledgerCursors = <String?>[];
  final withdrawalCursors = <String?>[];
  final requestedAmounts = <int>[];
  final savedBankAccounts = <Map<String, String>>[];
  int summaryCalls = 0;

  CursorPage<T> _page<T>(List<T> all, String? cursor) {
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, all.length);
    return CursorPage(
      items: all.sublist(start, end),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<WalletSummary> summary() async {
    summaryCalls++;
    if (summaryError != null) throw summaryError!;
    return wallet;
  }

  @override
  Future<CursorPage<LedgerEntry>> ledger({String? cursor, int? limit}) async {
    ledgerCursors.add(cursor);
    if (ledgerError != null) throw ledgerError!;
    return _page(ledgerEntries, cursor);
  }

  @override
  Future<BankAccountInfo> saveBankAccount({
    required String holderName,
    required String ifsc,
    required String accountNumber,
  }) async {
    if (bankError != null) throw bankError!;
    savedBankAccounts.add({
      'holderName': holderName,
      'ifsc': ifsc,
      'accountNumber': accountNumber,
    });
    final info = BankAccountInfo(
      holderName: holderName,
      ifsc: ifsc,
      accountNumberLast4: accountNumber.substring(accountNumber.length - 4),
    );
    wallet = fakeWallet(
      balancePaise: wallet.balancePaise,
      pendingWithdrawalPaise: wallet.pendingWithdrawalPaise,
      minWithdrawalPaise: wallet.minWithdrawalPaise,
      withdrawalBlocked: wallet.withdrawalBlocked,
      bankAccount: info,
    );
    return info;
  }

  @override
  Future<Withdrawal> requestWithdrawal(int amountPaise) async {
    if (withdrawError != null) throw withdrawError!;
    requestedAmounts.add(amountPaise);
    final w = fakeWithdrawal(payouts.length + 100, amountPaise: amountPaise);
    payouts = [w, ...payouts];
    wallet = fakeWallet(
      balancePaise: wallet.balancePaise - amountPaise,
      pendingWithdrawalPaise: wallet.pendingWithdrawalPaise + amountPaise,
      minWithdrawalPaise: wallet.minWithdrawalPaise,
      bankAccount: wallet.bankAccount,
    );
    return w;
  }

  @override
  Future<CursorPage<Withdrawal>> withdrawals({
    String? cursor,
    int? limit,
  }) async {
    withdrawalCursors.add(cursor);
    return _page(payouts, cursor);
  }
}
