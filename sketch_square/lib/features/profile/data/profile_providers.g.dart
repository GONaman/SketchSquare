// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'98da82bee810ac651cba0a9a1e3fe796818e8e35';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$avatarPickerHash() => r'f2c3c4d1184483e1826830ac409eb05d096db73b';

/// See also [avatarPicker].
@ProviderFor(avatarPicker)
final avatarPickerProvider = Provider<AvatarPicker>.internal(
  avatarPicker,
  name: r'avatarPickerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$avatarPickerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvatarPickerRef = ProviderRef<AvatarPicker>;
String _$profileStatsHash() => r'759d96455bcef1499d6105b5f2fb1d98d20b91f6';

/// Public stats of the signed-in architect (`GET /architects/:id`).
///
/// Copied from [profileStats].
@ProviderFor(profileStats)
final profileStatsProvider = AutoDisposeFutureProvider<ProfileStats>.internal(
  profileStats,
  name: r'profileStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileStatsRef = AutoDisposeFutureProviderRef<ProfileStats>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
