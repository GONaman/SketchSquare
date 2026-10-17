import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../../upload/domain/drawing_record.dart';
import '../domain/manage_drawings_repository.dart';

class DioManageDrawingsRepository implements ManageDrawingsRepository {
  DioManageDrawingsRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<ManagedDrawing>> list({
    DrawingStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/me/drawings',
      queryParameters: {
        if (status != null) 'status': _wire(status),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return CursorPage.fromJson(res.data!, ManagedDrawing.fromJson);
  });

  @override
  Future<DrawingRecord> fetch(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/drawings/$id');
    return DrawingRecord.fromJson(res.data!);
  });

  @override
  Future<void> updatePublished(
    String id, {
    required String title,
    required String description,
    required int pricePaise,
  }) => _guard(() async {
    await _dio.patch<dynamic>(
      '/drawings/$id',
      data: {
        'title': title.trim(),
        'description': description.trim(),
        'pricePaise': pricePaise,
      },
    );
  });

  @override
  Future<void> delete(String id) =>
      _guard(() => _dio.delete<dynamic>('/drawings/$id'));

  static String _wire(DrawingStatus s) => switch (s) {
    DrawingStatus.draft => 'DRAFT',
    DrawingStatus.processing => 'PROCESSING',
    DrawingStatus.published => 'PUBLISHED',
    DrawingStatus.underReview => 'UNDER_REVIEW',
    DrawingStatus.removed => 'REMOVED',
    DrawingStatus.failed => 'FAILED',
  };
}
