import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/city_count.dart';
import '../domain/drawing_detail.dart';
import '../domain/drawing_search_query.dart';
import '../domain/drawing_summary.dart';
import '../domain/drawings_repository.dart';
import '../domain/review.dart';

class DioDrawingsRepository implements DrawingsRepository {
  DioDrawingsRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<DrawingSummary>> search(
    DrawingSearchQuery query, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/drawings/search',
      queryParameters: query.toQueryParameters(cursor: cursor, limit: limit),
    );
    return CursorPage.fromJson(res.data!, DrawingSummary.fromJson);
  });

  @override
  Future<DrawingDetail> getDrawing(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/drawings/$id');
    return DrawingDetail.fromJson(res.data!);
  });

  @override
  Future<CursorPage<Review>> listReviews(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/drawings/$drawingId/reviews',
      queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
    );
    return CursorPage.fromJson(res.data!, Review.fromJson);
  });

  @override
  Future<List<CategoryRef>> listCategories() => _guard(() async {
    final res = await _dio.get<List<dynamic>>('/categories');
    return [
      for (final c in res.data!)
        CategoryRef.fromJson(c as Map<String, dynamic>),
    ];
  });

  @override
  Future<List<CityCount>> listCities() => _guard(() async {
    final res = await _dio.get<List<dynamic>>('/cities');
    return [
      for (final c in res.data!) CityCount.fromJson(c as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> requestCategory(String name) => _guard(() async {
    await _dio.post<void>('/category-requests', data: {'name': name});
  });
}
