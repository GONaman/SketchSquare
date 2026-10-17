import '../../../core/network/cursor_page.dart';
import 'city_count.dart';
import 'drawing_detail.dart';
import 'drawing_search_query.dart';
import 'drawing_summary.dart';
import 'review.dart';

/// Read side of discovery (docs/API_CONTRACT.md "Discovery", "Categories, cities").
/// Implementations convert failures to `ApiException` via `toApiException`.
abstract interface class DrawingsRepository {
  Future<CursorPage<DrawingSummary>> search(
    DrawingSearchQuery query, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  Future<DrawingDetail> getDrawing(String id);

  Future<CursorPage<Review>> listReviews(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  Future<List<CategoryRef>> listCategories();

  Future<List<CityCount>> listCities();

  Future<void> requestCategory(String name);
}
