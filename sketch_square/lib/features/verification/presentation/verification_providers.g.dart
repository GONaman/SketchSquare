// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$verificationRepositoryHash() =>
    r'ef543062b18a842ef8bd1033c61d271a3542e5a8';

/// See also [verificationRepository].
@ProviderFor(verificationRepository)
final verificationRepositoryProvider =
    Provider<VerificationRepository>.internal(
      verificationRepository,
      name: r'verificationRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$verificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VerificationRepositoryRef = ProviderRef<VerificationRepository>;
String _$documentPickerHash() => r'20de75b8c0fd06a2553a8b614f51ecdc5b1cb60e';

/// See also [documentPicker].
@ProviderFor(documentPicker)
final documentPickerProvider = Provider<DocumentPicker>.internal(
  documentPicker,
  name: r'documentPickerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentPickerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentPickerRef = ProviderRef<DocumentPicker>;
String _$myVerificationHash() => r'e2cf7361091151c63512c883f6ec881838625068';

/// The signed-in user's latest verification submission (`GET /verification/me`).
///
/// Copied from [myVerification].
@ProviderFor(myVerification)
final myVerificationProvider =
    AutoDisposeFutureProvider<VerificationRequest?>.internal(
      myVerification,
      name: r'myVerificationProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$myVerificationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyVerificationRef = AutoDisposeFutureProviderRef<VerificationRequest?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
