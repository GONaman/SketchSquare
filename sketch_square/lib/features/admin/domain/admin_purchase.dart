enum PurchaseStatus {
  created('CREATED'),
  paid('PAID'),
  failed('FAILED'),
  refunded('REFUNDED');

  const PurchaseStatus(this.wire);

  final String wire;

  static PurchaseStatus parse(String? value) => PurchaseStatus.values
      .firstWhere((s) => s.wire == value, orElse: () => PurchaseStatus.created);
}

enum RefundProviderStatus {
  pending,
  succeeded,
  failed;

  static RefundProviderStatus parse(String? value) =>
      RefundProviderStatus.values.firstWhere(
        (s) => s.name.toUpperCase() == value,
        orElse: () => RefundProviderStatus.pending,
      );
}

class AdminPerson {
  const AdminPerson({required this.id, required this.fullName, this.email});

  factory AdminPerson.fromJson(Map<String, dynamic> json) => AdminPerson(
    id: json['id'] as String,
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String?,
  );

  final String id;
  final String fullName;
  final String? email;
}

class AdminRefund {
  const AdminRefund({
    required this.id,
    required this.reason,
    required this.amountPaise,
    required this.refundedAt,
    required this.refundedBy,
    required this.providerStatus,
    this.providerRefundId,
    this.providerError,
  });

  factory AdminRefund.fromJson(Map<String, dynamic> json) => AdminRefund(
    id: json['id'] as String,
    reason: json['reason'] as String? ?? '',
    amountPaise: json['amountPaise'] as int,
    refundedAt: DateTime.parse(json['refundedAt'] as String),
    refundedBy: AdminPerson.fromJson(
      json['refundedBy'] as Map<String, dynamic>,
    ),
    providerStatus: RefundProviderStatus.parse(
      json['providerStatus'] as String?,
    ),
    providerRefundId: json['providerRefundId'] as String?,
    providerError: json['providerError'] as String?,
  );

  final String id;
  final String reason;
  final int amountPaise;
  final DateTime refundedAt;
  final AdminPerson refundedBy;
  final RefundProviderStatus providerStatus;
  final String? providerRefundId;
  final String? providerError;
}

/// Item of `GET /admin/purchases`; [sellerBalancePaise] is only sent by
/// `GET /admin/purchases/:id`.
class AdminPurchase {
  const AdminPurchase({
    required this.id,
    required this.status,
    required this.pricePaise,
    required this.platformFeePaise,
    required this.sellerNetPaise,
    required this.createdAt,
    required this.buyer,
    required this.seller,
    required this.drawingId,
    required this.drawingTitle,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paidAt,
    this.refund,
    this.sellerBalancePaise,
  });

  factory AdminPurchase.fromJson(Map<String, dynamic> json) {
    final drawing = json['drawing'] as Map<String, dynamic>;
    final refund = json['refund'] as Map<String, dynamic>?;
    final paidAt = json['paidAt'] as String?;
    return AdminPurchase(
      id: json['id'] as String,
      status: PurchaseStatus.parse(json['status'] as String?),
      pricePaise: json['pricePaise'] as int,
      platformFeePaise: json['platformFeePaise'] as int,
      sellerNetPaise: json['sellerNetPaise'] as int,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      paidAt: paidAt == null ? null : DateTime.parse(paidAt),
      buyer: AdminPerson.fromJson(json['buyer'] as Map<String, dynamic>),
      seller: AdminPerson.fromJson(json['seller'] as Map<String, dynamic>),
      drawingId: drawing['id'] as String,
      drawingTitle: drawing['title'] as String? ?? '',
      refund: refund == null ? null : AdminRefund.fromJson(refund),
      sellerBalancePaise: json['sellerBalancePaise'] as int?,
    );
  }

  final String id;
  final PurchaseStatus status;
  final int pricePaise;
  final int platformFeePaise;
  final int sellerNetPaise;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final AdminPerson buyer;
  final AdminPerson seller;
  final String drawingId;
  final String drawingTitle;
  final AdminRefund? refund;
  final int? sellerBalancePaise;

  bool get canRefund => status == PurchaseStatus.paid;
}

/// Response of `POST /admin/purchases/:id/refund`.
class RefundResult {
  const RefundResult({required this.alreadyRefunded, required this.refund});

  factory RefundResult.fromJson(Map<String, dynamic> json) => RefundResult(
    alreadyRefunded: json['alreadyRefunded'] as bool? ?? false,
    refund: AdminRefund.fromJson(json['refund'] as Map<String, dynamic>),
  );

  final bool alreadyRefunded;
  final AdminRefund refund;
}
