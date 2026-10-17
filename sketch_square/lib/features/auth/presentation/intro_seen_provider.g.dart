// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_seen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$introSeenHash() => r'7366d56b5dec21a87329268c3159ff7bd217bbad';

/// Whether the onboarding video has been dealt with (watched, skipped, or the
/// user signed in) on this device. Drives where logged-out users land.
///
/// Copied from [IntroSeen].
@ProviderFor(IntroSeen)
final introSeenProvider = NotifierProvider<IntroSeen, bool>.internal(
  IntroSeen.new,
  name: r'introSeenProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$introSeenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IntroSeen = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
