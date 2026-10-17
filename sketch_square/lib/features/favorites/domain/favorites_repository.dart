import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';

/// `GET /me/favorites` (docs/API_CONTRACT.md "Favorites"). Adding/removing a
/// favorite lives in `DrawingActionsRepository.setFavorite`.
abstract interface class FavoritesRepository {
  Future<CursorPage<DrawingSummary>> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });
}
