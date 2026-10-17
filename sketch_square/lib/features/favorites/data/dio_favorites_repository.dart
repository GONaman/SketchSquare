import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../domain/favorites_repository.dart';

class DioFavoritesRepository implements FavoritesRepository {
  DioFavoritesRepository(this._dio);

  final Dio _dio;

  @override
  Future<CursorPage<DrawingSummary>> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/me/favorites',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
      );
      return CursorPage.fromJson(
        res.data! as Map<String, dynamic>,
        DrawingSummary.fromJson,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }
}
