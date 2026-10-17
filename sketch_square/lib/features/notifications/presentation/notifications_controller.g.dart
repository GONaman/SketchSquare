// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadNotificationCountHash() =>
    r'ae6db6d35793c09fd03ee1f1f9bc097c6c6907e5';

/// Unread badge count; 0 until the inbox has loaded (or if it failed).
///
/// Copied from [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$notificationsControllerHash() =>
    r'ef20a4b46f7b2c2e6b5238b5f23ef9f360424ce6';

/// The in-app inbox (`GET /me/notifications`) with the unread badge count.
///
/// Copied from [NotificationsController].
@ProviderFor(NotificationsController)
final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, InboxState>.internal(
      NotificationsController.new,
      name: r'notificationsControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$notificationsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationsController = AsyncNotifier<InboxState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
