// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStatusHash() =>
    r'04c9369d893fba2196f30f926d6817e21cccf961';

/// Whether the API is reachable (`true` = online).
///
/// Driven by the HTTP layer instead of a platform plugin: a connection failure
/// flips it offline, any server response flips it back. While offline it polls
/// `GET /health` so the banner clears by itself once the network returns.
///
/// Copied from [ConnectivityStatus].
@ProviderFor(ConnectivityStatus)
final connectivityStatusProvider =
    NotifierProvider<ConnectivityStatus, bool>.internal(
      ConnectivityStatus.new,
      name: r'connectivityStatusProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$connectivityStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectivityStatus = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
