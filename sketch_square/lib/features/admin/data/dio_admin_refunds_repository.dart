import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/admin_purchase.dart';
import '../domain/admin_refunds_repository.dart';

class DioAdminRefundsRepository implements AdminRefundsRepository {
  DioAdminRefundsRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<AdminPurchase>> purchases({
    String? q,
    PurchaseStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/purchases',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null) 'status': status.wire,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromJson(res.data!, AdminPurchase.fromJson);
  });

  @override
  Future<AdminPurchase> purchase(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/purchases/$id');
    return AdminPurchase.fromJson(res.data!);
  });

  @override
  Future<RefundResult> refund(String id, {required String reason}) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/admin/purchases/$id/refund',
          data: {'reason': reason},
        );
        return RefundResult.fromJson(res.data!);
      });
}
