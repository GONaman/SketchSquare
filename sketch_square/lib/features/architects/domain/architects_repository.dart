import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import 'architect_profile.dart';

abstract interface class ArchitectsRepository {
  /// `GET /architects/top` (needs >= 3 ratings to qualify; sorted by rating).
  Future<List<TopArchitect>> top({String? city});

  /// `GET /architects/:id`: summary plus the first page of drawings.
  Future<ArchitectProfile> getArchitect(String id);

  Future<CursorPage<DrawingSummary>> listDrawings(
    String architectId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });
}
