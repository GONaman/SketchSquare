/// Wallet DTOs, see "Wallet" in docs/API_CONTRACT.md. All money is integer paise.
class BankAccountInfo {
  const BankAccountInfo({
    required this.holderName,
    required this.ifsc,
    required this.accountNumberLast4,
  });

  factory BankAccountInfo.fromJson(Map<String, dynamic> json) =>
      BankAccountInfo(
        holderName: json['holderName'] as String,
        ifsc: json['ifsc'] as String,
        accountNumberLast4: json['accountNumberLast4'] as String,
      );

  final String holderName;
  final String ifsc;
  final String accountNumberLast4;

  /// The full number is never sent back by the API.
  String get maskedNumber => 'XXXX XXXX $accountNumberLast4';
}

class WalletSummary {
  const WalletSummary({
    required this.balancePaise,
    required this.pendingWithdrawalPaise,
    required this.minWithdrawalPaise,
    required this.withdrawalBlocked,
    this.bankAccount,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
    balancePaise: json['balancePaise'] as int,
    pendingWithdrawalPaise: json['pendingWithdrawalPaise'] as int? ?? 0,
    minWithdrawalPaise: json['minWithdrawalPaise'] as int? ?? 0,
    withdrawalBlocked: json['withdrawalBlocked'] as bool? ?? false,
    bankAccount:
        json['bankAccount'] == null
            ? null
            : BankAccountInfo.fromJson(
              json['bankAccount'] as Map<String, dynamic>,
            ),
  );

  final int balancePaise;
  final int pendingWithdrawalPaise;
  final int minWithdrawalPaise;
  final bool withdrawalBlocked;
  final BankAccountInfo? bankAccount;

  WalletSummary copyWith({BankAccountInfo? bankAccount}) => WalletSummary(
    balancePaise: balancePaise,
    pendingWithdrawalPaise: pendingWithdrawalPaise,
    minWithdrawalPaise: minWithdrawalPaise,
    withdrawalBlocked: withdrawalBlocked,
    bankAccount: bankAccount ?? this.bankAccount,
  );
}

enum LedgerEntryType {
  sale('SALE', 'Sale'),
  platformFee('PLATFORM_FEE', 'Platform fee'),
  withdrawal('WITHDRAWAL', 'Withdrawal'),
  withdrawalReversal('WITHDRAWAL_REVERSAL', 'Withdrawal reversed'),
  refund('REFUND', 'Refund'),
  other('', 'Transaction');

  const LedgerEntryType(this.wire, this.label);
  final String wire;
  final String label;

  static LedgerEntryType parse(String? raw) => values.firstWhere(
    (t) => t.wire == raw && t != other,
    orElse: () => other,
  );
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.entryType,
    required this.amountPaise,
    required this.createdAt,
    this.description,
    this.referenceId,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    entryType: LedgerEntryType.parse(json['entryType'] as String?),
    amountPaise: json['amountPaise'] as int,
    description: json['description'] as String?,
    referenceId: json['referenceId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final LedgerEntryType entryType;

  /// Signed: credits positive, debits negative.
  final int amountPaise;
  final String? description;
  final String? referenceId;
  final DateTime createdAt;

  bool get isCredit => amountPaise >= 0;

  String get title =>
      description != null && description!.trim().isNotEmpty
          ? description!
          : entryType.label;
}

enum WithdrawalStatus {
  requested('REQUESTED', 'Requested'),
  processing('PROCESSING', 'Processing'),
  paid('PAID', 'Paid'),
  failed('FAILED', 'Failed');

  const WithdrawalStatus(this.wire, this.label);
  final String wire;
  final String label;

  static WithdrawalStatus parse(String? raw) => values.firstWhere(
    (s) => s.wire == raw,
    orElse: () => WithdrawalStatus.requested,
  );
}

class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
    id: json['id'] as String,
    amountPaise: json['amountPaise'] as int,
    status: WithdrawalStatus.parse(json['status'] as String?),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final int amountPaise;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
