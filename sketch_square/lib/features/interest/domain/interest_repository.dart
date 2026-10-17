import '../../../core/network/cursor_page.dart';

/// One architect who tapped "I'm interested" on a paid drawing.
class InterestedUser {
  const InterestedUser({
    required this.id,
    required this.fullName,
    this.city,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String? city;
  final DateTime createdAt;

  factory InterestedUser.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return InterestedUser(
      id: user['id'] as String? ?? '',
      fullName: user['fullName'] as String? ?? 'Unknown',
      city: user['city'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// "I'm interested" signals on paid drawings (docs/API_CONTRACT.md,
/// "Interest"). Implementations throw `ApiException`.
abstract interface class InterestRepository {
  /// `PUT|DELETE /drawings/:id/interest` (idempotent; 400 for free drawings,
  /// 403 for your own).
  Future<void> setInterest(String drawingId, {required bool interested});

  /// `GET /drawings/:id/interests`, owner only, newest first.
  Future<CursorPage<InterestedUser>> listInterested(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });
}
