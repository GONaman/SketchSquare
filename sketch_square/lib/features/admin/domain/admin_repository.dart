import '../../../core/network/cursor_page.dart';
import 'admin_verification.dart';

abstract interface class AdminRepository {
  /// Verification requests with the given status ([pending] by default),
  /// oldest first as the server orders them.
  Future<CursorPage<AdminVerification>> verifications({
    String status = 'PENDING',
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  /// Includes the presigned `documentUrl`.
  Future<AdminVerification> verification(String id);

  Future<void> approve(String id);

  Future<void> reject(String id, {required String note});
}
