// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manage_drawings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manageFilterControllerHash() =>
    r'b8f1262a0a71980d823a2b15b45be6e9aa6164e2';

/// See also [ManageFilterController].
@ProviderFor(ManageFilterController)
final manageFilterControllerProvider =
    AutoDisposeNotifierProvider<ManageFilterController, ManageFilter>.internal(
      ManageFilterController.new,
      name: r'manageFilterControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$manageFilterControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ManageFilterController = AutoDisposeNotifier<ManageFilter>;
String _$managedDrawingsControllerHash() =>
    r'5f7ed5859a0137f6f31797ef2141da0e9e0f4523';

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

abstract class _$ManagedDrawingsController
    extends BuildlessAutoDisposeAsyncNotifier<PagedState<ManagedDrawing>> {
  late final ManageFilter filter;

  FutureOr<PagedState<ManagedDrawing>> build(ManageFilter filter);
}

/// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
///
/// Copied from [ManagedDrawingsController].
@ProviderFor(ManagedDrawingsController)
const managedDrawingsControllerProvider = ManagedDrawingsControllerFamily();

/// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
///
/// Copied from [ManagedDrawingsController].
class ManagedDrawingsControllerFamily
    extends Family<AsyncValue<PagedState<ManagedDrawing>>> {
  /// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
  ///
  /// Copied from [ManagedDrawingsController].
  const ManagedDrawingsControllerFamily();

  /// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
  ///
  /// Copied from [ManagedDrawingsController].
  ManagedDrawingsControllerProvider call(ManageFilter filter) {
    return ManagedDrawingsControllerProvider(filter);
  }

  @override
  ManagedDrawingsControllerProvider getProviderOverride(
    covariant ManagedDrawingsControllerProvider provider,
  ) {
    return call(provider.filter);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'managedDrawingsControllerProvider';
}

/// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
///
/// Copied from [ManagedDrawingsController].
class ManagedDrawingsControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ManagedDrawingsController,
          PagedState<ManagedDrawing>
        > {
  /// The seller's drawings for one [ManageFilter] (family key), cursor-paginated.
  ///
  /// Copied from [ManagedDrawingsController].
  ManagedDrawingsControllerProvider(ManageFilter filter)
    : this._internal(
        () => ManagedDrawingsController()..filter = filter,
        from: managedDrawingsControllerProvider,
        name: r'managedDrawingsControllerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$managedDrawingsControllerHash,
        dependencies: ManagedDrawingsControllerFamily._dependencies,
        allTransitiveDependencies:
            ManagedDrawingsControllerFamily._allTransitiveDependencies,
        filter: filter,
      );

  ManagedDrawingsControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final ManageFilter filter;

  @override
  FutureOr<PagedState<ManagedDrawing>> runNotifierBuild(
    covariant ManagedDrawingsController notifier,
  ) {
    return notifier.build(filter);
  }

  @override
  Override overrideWith(ManagedDrawingsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ManagedDrawingsControllerProvider._internal(
        () => create()..filter = filter,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ManagedDrawingsController,
    PagedState<ManagedDrawing>
  >
  createElement() {
    return _ManagedDrawingsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ManagedDrawingsControllerProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ManagedDrawingsControllerRef
    on AutoDisposeAsyncNotifierProviderRef<PagedState<ManagedDrawing>> {
  /// The parameter `filter` of this provider.
  ManageFilter get filter;
}

class _ManagedDrawingsControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ManagedDrawingsController,
          PagedState<ManagedDrawing>
        >
    with ManagedDrawingsControllerRef {
  _ManagedDrawingsControllerProviderElement(super.provider);

  @override
  ManageFilter get filter =>
      (origin as ManagedDrawingsControllerProvider).filter;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
