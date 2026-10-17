import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_verification.dart';

class DioAdminRepository implements AdminRepository {
  DioAdminRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<AdminVerification>> verifications({
    String status = 'PENDING',
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/verifications',
      queryParameters: {
        'status': status,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromJson(res.data!, AdminVerification.fromJson);
  });

  @override
  Future<AdminVerification> verification(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/verifications/$id',
    );
    return AdminVerification.fromJson(res.data!);
  });

  @override
  Future<void> approve(String id) =>
      _guard(() => _dio.post<void>('/admin/verifications/$id/approve'));

  @override
  Future<void> reject(String id, {required String note}) => _guard(
    () => _dio.post<void>(
      '/admin/verifications/$id/reject',
      data: {'note': note},
    ),
  );
}
