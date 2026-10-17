// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$draftStoreHash() => r'a9d13cceb66c39c3ddda5ddaa8acdd57f832aa99';

/// See also [draftStore].
@ProviderFor(draftStore)
final draftStoreProvider = Provider<DraftStore>.internal(
  draftStore,
  name: r'draftStoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$draftStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DraftStoreRef = ProviderRef<DraftStore>;
String _$uploadDelayHash() => r'9546253432bcc5424bfe0e8fd4ef3cb494292348';

/// Delay used between processing-status polls; tests override it to run instantly.
///
/// Copied from [uploadDelay].
@ProviderFor(uploadDelay)
final uploadDelayProvider = Provider<Future<void> Function(Duration)>.internal(
  uploadDelay,
  name: r'uploadDelayProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uploadDelayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadDelayRef = ProviderRef<Future<void> Function(Duration)>;
String _$uploadRepositoryHash() => r'68b67202a96d59c7abd69238655bce10eb7da796';

/// Screens depend on the interface providers so tests can override them.
///
/// Copied from [uploadRepository].
@ProviderFor(uploadRepository)
final uploadRepositoryProvider = Provider<UploadRepository>.internal(
  uploadRepository,
  name: r'uploadRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadRepositoryRef = ProviderRef<UploadRepository>;
String _$sheetUploaderHash() => r'988880c7cf705115c3818e880d92709454b042bf';

/// See also [sheetUploader].
@ProviderFor(sheetUploader)
final sheetUploaderProvider = Provider<SheetUploader>.internal(
  sheetUploader,
  name: r'sheetUploaderProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sheetUploaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SheetUploaderRef = ProviderRef<SheetUploader>;
String _$sheetPickerHash() => r'0840259414002bd253f11af6559b47c9360205d1';

/// See also [sheetPicker].
@ProviderFor(sheetPicker)
final sheetPickerProvider = Provider<SheetPicker>.internal(
  sheetPicker,
  name: r'sheetPickerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sheetPickerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SheetPickerRef = ProviderRef<SheetPicker>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
