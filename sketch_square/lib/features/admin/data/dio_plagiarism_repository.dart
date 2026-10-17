import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/plagiarism_flag.dart';
import '../domain/plagiarism_repository.dart';

class DioPlagiarismRepository implements PlagiarismRepository {
  DioPlagiarismRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<PlagiarismFlag>> flags({
    PlagiarismFlagStatus status = PlagiarismFlagStatus.pending,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/plagiarism-flags',
      queryParameters: {
        'status': status.wire,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromJson(res.data!, PlagiarismFlag.fromJson);
  });

  @override
  Future<void> approve(String id) =>
      _guard(() => _dio.post<void>('/admin/plagiarism-flags/$id/approve'));

  @override
  Future<void> reject(String id, {required String reason}) => _guard(
    () => _dio.post<void>(
      '/admin/plagiarism-flags/$id/reject',
      data: {'reason': reason},
    ),
  );
}
