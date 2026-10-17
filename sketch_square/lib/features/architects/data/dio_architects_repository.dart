import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../domain/architect_profile.dart';
import '../domain/architects_repository.dart';

class DioArchitectsRepository implements ArchitectsRepository {
  DioArchitectsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<TopArchitect>> top({String? city}) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/architects/top',
        queryParameters: {if (city != null) 'city': city},
      );
      return [
        for (final a in res.data!)
          TopArchitect.fromJson(a as Map<String, dynamic>),
      ];
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<ArchitectProfile> getArchitect(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/architects/$id');
      return ArchitectProfile.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<DrawingSummary>> listDrawings(
    String architectId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/architects/$architectId/drawings',
        queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
      );
      return CursorPage.fromJson(res.data!, DrawingSummary.fromJson);
    } catch (e) {
      throw toApiException(e);
    }
  }
}
