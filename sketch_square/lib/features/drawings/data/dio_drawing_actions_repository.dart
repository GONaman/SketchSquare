import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/drawing_actions_repository.dart';

class DioDrawingActionsRepository implements DrawingActionsRepository {
  DioDrawingActionsRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> addToCart(String drawingId) async {
    try {
      await _dio.post<void>('/cart', data: {'drawingId': drawingId});
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<void> setFavorite(String drawingId, {required bool favorite}) async {
    try {
      final path = '/drawings/$drawingId/favorite';
      await (favorite ? _dio.put<void>(path) : _dio.delete<void>(path));
    } catch (e) {
      throw toApiException(e);
    }
  }
}
