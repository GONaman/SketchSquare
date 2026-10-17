import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/admin/domain/admin_purchase.dart';
import 'package:sketch_square/features/admin/domain/admin_refunds_repository.dart';

AdminRefund makeAdminRefund({
  String reason = 'Duplicate purchase',
  RefundProviderStatus providerStatus = RefundProviderStatus.succeeded,
  String? providerError,
}) => AdminRefund(
  id: 'r1',
  reason: reason,
  amountPaise: 50000,
  refundedAt: DateTime.utc(2026, 2, 3, 4),
  refundedBy: const AdminPerson(id: 'admin', fullName: 'Ada Admin'),
  providerStatus: providerStatus,
  providerRefundId:
      providerStatus == RefundProviderStatus.succeeded ? 'rfnd_1' : null,
  providerError: providerError,
);

AdminPurchase makeAdminPurchase(
  String id, {
  String title = 'Modern Villa',
  String buyer = 'Bella Buyer',
  PurchaseStatus status = PurchaseStatus.paid,
  int pricePaise = 50000,
  int sellerNetPaise = 45000,
  AdminRefund? refund,
  int? sellerBalancePaise,
}) => AdminPurchase(
  id: id,
  status: status,
  pricePaise: pricePaise,
  platformFeePaise: pricePaise - sellerNetPaise,
  sellerNetPaise: sellerNetPaise,
  razorpayOrderId: 'order_$id',
  razorpayPaymentId: 'pay_$id',
  createdAt: DateTime.utc(2026, 2, 1, 10),
  paidAt: DateTime.utc(2026, 2, 1, 10, 5),
  buyer: AdminPerson(id: 'b-$id', fullName: buyer, email: '$id@buyer.test'),
  seller: AdminPerson(id: 's-$id', fullName: 'Sam Seller', email: 's@x.test'),
  drawingId: 'd-$id',
  drawingTitle: title,
  refund: refund,
  sellerBalancePaise: sellerBalancePaise,
);

/// In-memory [AdminRefundsRepository]; pages are served `pageSize` at a time.
class FakeAdminRefundsRepository implements AdminRefundsRepository {
  FakeAdminRefundsRepository({List<AdminPurchase>? items, this.pageSize = 20})
    : items = items ?? [];

  final List<AdminPurchase> items;
  final int pageSize;
  int sellerBalance = 100000;
  ApiException? listError;
  ApiException? detailError;
  ApiException? refundError;

  /// Provider outcome of the next refund call.
  RefundProviderStatus nextProviderStatus = RefundProviderStatus.succeeded;
  final queries = <({String? q, PurchaseStatus? status, String? cursor})>[];
  final refunds = <({String id, String reason})>[];

  @override
  Future<CursorPage<AdminPurchase>> purchases({
    String? q,
    PurchaseStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    queries.add((q: q, status: status, cursor: cursor));
    if (listError != null) throw listError!;
    final needle = (q ?? '').toLowerCase();
    final matching = [
      for (final p in items)
        if ((status == null || p.status == status) &&
            (needle.isEmpty ||
                p.drawingTitle.toLowerCase().contains(needle) ||
                p.buyer.fullName.toLowerCase().contains(needle)))
          p,
    ];
    final start = int.parse(cursor ?? '0');
    final end = (start + pageSize).clamp(0, matching.length);
    return CursorPage(
      items: matching.sublist(start, end),
      nextCursor: end < matching.length ? '$end' : null,
    );
  }

  @override
  Future<AdminPurchase> purchase(String id) async {
    if (detailError != null) throw detailError!;
    final p = items.firstWhere((x) => x.id == id);
    return makeAdminPurchase(
      p.id,
      title: p.drawingTitle,
      buyer: p.buyer.fullName,
      status: p.status,
      pricePaise: p.pricePaise,
      sellerNetPaise: p.sellerNetPaise,
      refund: p.refund,
      sellerBalancePaise: sellerBalance,
    );
  }

  @override
  Future<RefundResult> refund(String id, {required String reason}) async {
    if (refundError != null) throw refundError!;
    refunds.add((id: id, reason: reason));
    final i = items.indexWhere((x) => x.id == id);
    final old = items[i];
    final already = old.status == PurchaseStatus.refunded;
    final refund = makeAdminRefund(
      reason: already ? old.refund!.reason : reason,
      providerStatus: nextProviderStatus,
      providerError:
          nextProviderStatus == RefundProviderStatus.failed
              ? 'gateway down'
              : null,
    );
    items[i] = makeAdminPurchase(
      old.id,
      title: old.drawingTitle,
      buyer: old.buyer.fullName,
      status: PurchaseStatus.refunded,
      pricePaise: old.pricePaise,
      sellerNetPaise: old.sellerNetPaise,
      refund: refund,
    );
    return RefundResult(alreadyRefunded: already, refund: refund);
  }
}
