// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'architect_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$architectProfileControllerHash() =>
    r'8f0dc7b0d8d962f469aa49b2c99bc8af103bf5cb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ArchitectProfileController
    extends BuildlessAutoDisposeAsyncNotifier<ArchitectProfileState> {
  late final String architectId;

  FutureOr<ArchitectProfileState> build(String architectId);
}

/// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
///
/// Copied from [ArchitectProfileController].
@ProviderFor(ArchitectProfileController)
const architectProfileControllerProvider = ArchitectProfileControllerFamily();

/// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
///
/// Copied from [ArchitectProfileController].
class ArchitectProfileControllerFamily
    extends Family<AsyncValue<ArchitectProfileState>> {
  /// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
  ///
  /// Copied from [ArchitectProfileController].
  const ArchitectProfileControllerFamily();

  /// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
  ///
  /// Copied from [ArchitectProfileController].
  ArchitectProfileControllerProvider call(String architectId) {
    return ArchitectProfileControllerProvider(architectId);
  }

  @override
  ArchitectProfileControllerProvider getProviderOverride(
    covariant ArchitectProfileControllerProvider provider,
  ) {
    return call(provider.architectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'architectProfileControllerProvider';
}

/// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
///
/// Copied from [ArchitectProfileController].
class ArchitectProfileControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ArchitectProfileController,
          ArchitectProfileState
        > {
  /// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
  ///
  /// Copied from [ArchitectProfileController].
  ArchitectProfileControllerProvider(String architectId)
    : this._internal(
        () => ArchitectProfileController()..architectId = architectId,
        from: architectProfileControllerProvider,
        name: r'architectProfileControllerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$architectProfileControllerHash,
        dependencies: ArchitectProfileControllerFamily._dependencies,
        allTransitiveDependencies:
            ArchitectProfileControllerFamily._allTransitiveDependencies,
        architectId: architectId,
      );

  ArchitectProfileControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.architectId,
  }) : super.internal();

  final String architectId;

  @override
  FutureOr<ArchitectProfileState> runNotifierBuild(
    covariant ArchitectProfileController notifier,
  ) {
    return notifier.build(architectId);
  }

  @override
  Override overrideWith(ArchitectProfileController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ArchitectProfileControllerProvider._internal(
        () => create()..architectId = architectId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        architectId: architectId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ArchitectProfileController,
    ArchitectProfileState
  >
  createElement() {
    return _ArchitectProfileControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ArchitectProfileControllerProvider &&
        other.architectId == architectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, architectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ArchitectProfileControllerRef
    on AutoDisposeAsyncNotifierProviderRef<ArchitectProfileState> {
  /// The parameter `architectId` of this provider.
  String get architectId;
}

class _ArchitectProfileControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ArchitectProfileController,
          ArchitectProfileState
        >
    with ArchitectProfileControllerRef {
  _ArchitectProfileControllerProviderElement(super.provider);

  @override
  String get architectId =>
      (origin as ArchitectProfileControllerProvider).architectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
