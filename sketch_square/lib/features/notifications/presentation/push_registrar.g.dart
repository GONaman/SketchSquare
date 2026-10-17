// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registrar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pushRegistrarHash() => r'd9a9a2b64c06891b72ecd03114176525b7594500';

/// See also [pushRegistrar].
@ProviderFor(pushRegistrar)
final pushRegistrarProvider = Provider<PushRegistrar>.internal(
  pushRegistrar,
  name: r'pushRegistrarProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pushRegistrarHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushRegistrarRef = ProviderRef<PushRegistrar>;
String _$pushRegistrationHash() => r'6a0c1fe7a38a57c55e2afc3773416a4b2b9728b9';

/// Mounted once at the app root: registers the device token whenever a user
/// signs in. Sign-out is handled by `AuthController.signOut`, which must
/// unregister before the access token is cleared.
///
/// Copied from [pushRegistration].
@ProviderFor(pushRegistration)
final pushRegistrationProvider = Provider<void>.internal(
  pushRegistration,
  name: r'pushRegistrationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pushRegistrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushRegistrationRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
