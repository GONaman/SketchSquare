import '../../../core/network/cursor_page.dart';
import 'app_notification.dart';

/// The in-app notification inbox. Implementations throw `ApiException`.
abstract interface class NotificationsRepository {
  /// `GET /me/notifications`, newest first.
  Future<NotificationsPage> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  /// `POST /me/notifications/read`; null [ids] marks everything read.
  Future<void> markRead({List<String>? ids});
}

/// Push token bookkeeping (`POST|DELETE /me/device-tokens`).
abstract interface class DeviceTokensRepository {
  Future<void> register(String token, {required String platform});

  Future<void> unregister(String token);
}
