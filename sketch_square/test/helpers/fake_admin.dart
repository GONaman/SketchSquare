import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/admin/domain/admin_repository.dart';
import 'package:sketch_square/features/admin/domain/admin_verification.dart';
import 'package:sketch_square/features/auth/domain/user.dart';

AdminVerification makeAdminVerification(
  String id, {
  String name = 'Asha Rao',
  VerificationStatus status = VerificationStatus.pending,
  String? documentUrl,
  String? reviewNote,
}) => AdminVerification(
  id: id,
  status: status,
  coaRegistrationNumber: 'CA/2015/$id',
  submittedAt: DateTime.utc(2026, 1, 2, 10),
  user: AdminApplicant(
    id: 'u-$id',
    fullName: name,
    email: '$id@example.com',
    phone: '+919999999999',
    city: 'Bengaluru',
    address: '12 MG Road',
  ),
  documentUrl: documentUrl,
  reviewNote: reviewNote,
);

/// In-memory [AdminRepository]; pages are served `pageSize` at a time.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({List<AdminVerification>? items, this.pageSize = 20})
    : items = items ?? [];

  final List<AdminVerification> items;
  final int pageSize;
  ApiException? error;
  ApiException? listError;
  final approved = <String>[];
  final rejected = <({String id, String note})>[];
  final cursors = <String?>[];

  @override
  Future<CursorPage<AdminVerification>> verifications({
    String status = 'PENDING',
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    cursors.add(cursor);
    if (listError != null) throw listError!;
    final pending =
        items.where((v) => v.status.name.toUpperCase() == status).toList();
    final start = int.parse(cursor ?? '0');
    final end = (start + pageSize).clamp(0, pending.length);
    return CursorPage(
      items: pending.sublist(start, end),
      nextCursor: end < pending.length ? '$end' : null,
    );
  }

  @override
  Future<AdminVerification> verification(String id) async {
    if (error != null) throw error!;
    return items.firstWhere((v) => v.id == id);
  }

  @override
  Future<void> approve(String id) async {
    if (error != null) throw error!;
    approved.add(id);
    items.removeWhere((v) => v.id == id);
  }

  @override
  Future<void> reject(String id, {required String note}) async {
    if (error != null) throw error!;
    rejected.add((id: id, note: note));
    items.removeWhere((v) => v.id == id);
  }
}
