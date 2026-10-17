import '../../../core/network/cursor_page.dart';
import 'admin_purchase.dart';

/// ADMIN purchase search and refunds (Part 3).
abstract interface class AdminRefundsRepository {
  /// Newest first. [q] searches ids, buyer/seller and drawing title; a null
  /// [status] returns every status.
  Future<CursorPage<AdminPurchase>> purchases({
    String? q,
    PurchaseStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  /// Includes `sellerBalancePaise`.
  Future<AdminPurchase> purchase(String id);

  /// Idempotent: repeating it on a refunded purchase retries only a failed
  /// gateway refund.
  Future<RefundResult> refund(String id, {required String reason});
}
