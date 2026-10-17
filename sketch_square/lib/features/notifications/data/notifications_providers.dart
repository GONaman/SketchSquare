import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/notifications_repository.dart';
import '../domain/push_service.dart';
import 'dio_notifications_repository.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    DioNotificationsRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
DeviceTokensRepository deviceTokensRepository(Ref ref) =>
    DioDeviceTokensRepository(ref.watch(dioProvider));

/// Override with a Firebase-backed [PushService] once FCM credentials exist
/// (see the TODO on [PushService]).
@Riverpod(keepAlive: true)
PushService pushService(Ref ref) => NoopPushService(
  platform:
      kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
);
