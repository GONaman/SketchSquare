// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsRepositoryHash() =>
    r'dc049a0763a11091eab3181da78152507fe8bfdb';

/// See also [notificationsRepository].
@ProviderFor(notificationsRepository)
final notificationsRepositoryProvider =
    Provider<NotificationsRepository>.internal(
      notificationsRepository,
      name: r'notificationsRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$notificationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsRepositoryRef = ProviderRef<NotificationsRepository>;
String _$deviceTokensRepositoryHash() =>
    r'556ae38d180f59a3b1d54b1cd17f7ab4a263d160';

/// See also [deviceTokensRepository].
@ProviderFor(deviceTokensRepository)
final deviceTokensRepositoryProvider =
    Provider<DeviceTokensRepository>.internal(
      deviceTokensRepository,
      name: r'deviceTokensRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$deviceTokensRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceTokensRepositoryRef = ProviderRef<DeviceTokensRepository>;
String _$pushServiceHash() => r'49c6561bfbf3a5345a9ff4ad1157d41c20d35dac';

/// Override with a Firebase-backed [PushService] once FCM credentials exist
/// (see the TODO on [PushService]).
///
/// Copied from [pushService].
@ProviderFor(pushService)
final pushServiceProvider = Provider<PushService>.internal(
  pushService,
  name: r'pushServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pushServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushServiceRef = ProviderRef<PushService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
