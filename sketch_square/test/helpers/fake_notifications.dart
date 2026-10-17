import 'dart:async';

import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/notifications/domain/app_notification.dart';
import 'package:sketch_square/features/notifications/domain/notifications_repository.dart';
import 'package:sketch_square/features/notifications/domain/push_service.dart';

AppNotification makeNotification(
  String id, {
  NotificationType type = NotificationType.saleMade,
  String title = 'You made a sale',
  String body = 'Net ₹450',
  bool read = false,
  Map<String, String> data = const {},
}) => AppNotification(
  id: id,
  type: type,
  title: title,
  body: body,
  data: data,
  readAt: read ? DateTime.utc(2026, 2, 2) : null,
  createdAt: DateTime.utc(2026, 2, 1, 12),
);

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    List<AppNotification>? items,
    this.pageSize = 20,
  }) : items = items ?? [];

  final List<AppNotification> items;
  final int pageSize;
  final cursors = <String?>[];
  final markedRead = <List<String>?>[];
  ApiException? listError;
  ApiException? markError;

  int get unread => items.where((n) => !n.isRead).length;

  @override
  Future<NotificationsPage> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    cursors.add(cursor);
    if (listError != null) throw listError!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, items.length);
    return NotificationsPage(
      page: CursorPage(
        items: items.sublist(start, end),
        nextCursor: end < items.length ? '$end' : null,
      ),
      unreadCount: unread,
    );
  }

  @override
  Future<void> markRead({List<String>? ids}) async {
    if (markError != null) throw markError!;
    markedRead.add(ids);
    for (var i = 0; i < items.length; i++) {
      if (ids == null || ids.contains(items[i].id)) {
        items[i] = items[i].markedRead(DateTime.utc(2026, 3));
      }
    }
  }
}

class FakeDeviceTokensRepository implements DeviceTokensRepository {
  final registered = <(String, String)>[];
  final unregistered = <String>[];
  ApiException? error;

  @override
  Future<void> register(String token, {required String platform}) async {
    if (error != null) throw error!;
    registered.add((token, platform));
  }

  @override
  Future<void> unregister(String token) async {
    if (error != null) throw error!;
    unregistered.add(token);
  }
}

/// A [PushService] with a scripted token and a controllable refresh stream.
class FakePushService implements PushService {
  FakePushService({this.token, this.platform = 'android'});

  String? token;
  @override
  final String platform;

  final _refresh = StreamController<String>.broadcast();

  void rotate(String next) => _refresh.add(next);

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;
}
