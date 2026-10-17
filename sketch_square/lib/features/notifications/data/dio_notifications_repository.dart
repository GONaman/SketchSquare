import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

class DioNotificationsRepository implements NotificationsRepository {
  DioNotificationsRepository(this._dio);

  final Dio _dio;

  @override
  Future<NotificationsPage> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/me/notifications',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
      );
      final json = res.data! as Map<String, dynamic>;
      return NotificationsPage(
        page: CursorPage.fromJson(json, AppNotification.fromJson),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<void> markRead({List<String>? ids}) async {
    try {
      await _dio.post<void>(
        '/me/notifications/read',
        data: {if (ids != null) 'ids': ids},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class DioDeviceTokensRepository implements DeviceTokensRepository {
  DioDeviceTokensRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> register(String token, {required String platform}) async {
    try {
      await _dio.post<void>(
        '/me/device-tokens',
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<void> unregister(String token) async {
    try {
      await _dio.delete<void>('/me/device-tokens', data: {'token': token});
    } catch (e) {
      throw toApiException(e);
    }
  }
}
