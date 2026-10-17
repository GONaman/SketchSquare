import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../../upload/domain/drawing_record.dart';

/// `stats` of a `GET /me/drawings` item (docs/API_CONTRACT.md).
class DrawingStats {
  const DrawingStats({
    this.viewCount = 0,
    this.purchaseCount = 0,
    this.avgRating = 0,
    this.ratingCount = 0,
  });

  final int viewCount;
  final int purchaseCount;
  final double avgRating;
  final int ratingCount;

  factory DrawingStats.fromJson(Map<String, dynamic> json) => DrawingStats(
    viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
    avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
  );
}

/// One row of the seller's drawing list.
class ManagedDrawing {
  const ManagedDrawing({
    required this.drawing,
    this.stats = const DrawingStats(),
  });

  final DrawingSummary drawing;
  final DrawingStats stats;

  String get id => drawing.id;

  factory ManagedDrawing.fromJson(Map<String, dynamic> json) => ManagedDrawing(
    drawing: DrawingSummary.fromJson(json['drawing'] as Map<String, dynamic>),
    stats: DrawingStats.fromJson(
      (json['stats'] as Map<String, dynamic>?) ?? const {},
    ),
  );

  ManagedDrawing withDrawing(DrawingSummary d) =>
      ManagedDrawing(drawing: d, stats: stats);
}

/// Seller-side drawing management. Statuses follow the contract:
/// DRAFT / PROCESSING / PUBLISHED / UNDER_REVIEW / FAILED (shown as "Rejected").
abstract interface class ManageDrawingsRepository {
  /// `GET /me/drawings`; a null [status] lists every status.
  Future<CursorPage<ManagedDrawing>> list({
    DrawingStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  /// `GET /drawings/:id`, for the fields the list summary lacks (description).
  Future<DrawingRecord> fetch(String id);

  /// `PATCH /drawings/:id` on a published drawing: only these fields are editable.
  Future<void> updatePublished(
    String id, {
    required String title,
    required String description,
    required int pricePaise,
  });

  /// `DELETE /drawings/:id` (status REMOVED; past buyers keep access).
  Future<void> delete(String id);
}
