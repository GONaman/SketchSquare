import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/interest_repository.dart';

class DioInterestRepository implements InterestRepository {
  DioInterestRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> setInterest(String drawingId, {required bool interested}) async {
    try {
      final path = '/drawings/$drawingId/interest';
      await (interested ? _dio.put<void>(path) : _dio.delete<void>(path));
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<InterestedUser>> listInterested(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/drawings/$drawingId/interests',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
      );
      return CursorPage.fromJson(
        res.data! as Map<String, dynamic>,
        InterestedUser.fromJson,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }
}
