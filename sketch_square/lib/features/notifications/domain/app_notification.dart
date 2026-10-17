import '../../../core/network/cursor_page.dart';

/// `Notification.type` (docs/API_CONTRACT.md "Phase 8"). Unknown types from a
/// newer server are kept as [unknown] and still listed.
enum NotificationType {
  verificationResult('VERIFICATION_RESULT'),
  saleMade('SALE_MADE'),
  withdrawalStatus('WITHDRAWAL_STATUS'),
  newReview('NEW_REVIEW'),
  interestReceived('INTEREST_RECEIVED'),
  unknown('');

  const NotificationType(this.wire);
  final String wire;

  static NotificationType parse(String? wire) => NotificationType.values
      .firstWhere((t) => t.wire == wire, orElse: () => unknown);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as Map<String, dynamic>?) ?? const {};
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.parse(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: {for (final e in raw.entries) e.key: '${e.value}'},
      readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// A `GET /me/notifications` page plus the server-wide unread count.
class NotificationsPage {
  const NotificationsPage({required this.page, required this.unreadCount});

  final CursorPage<AppNotification> page;
  final int unreadCount;
}
