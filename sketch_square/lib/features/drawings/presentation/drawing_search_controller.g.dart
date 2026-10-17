// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$drawingSearchControllerHash() =>
    r'd3bfdd28df5d66edbc929ddc708d5e9683046004';

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

abstract class _$DrawingSearchController
    extends BuildlessAutoDisposeAsyncNotifier<PagedState<DrawingSummary>> {
  late final DrawingSearchQuery query;

  FutureOr<PagedState<DrawingSummary>> build(DrawingSearchQuery query);
}

/// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
/// distinct query (family key); it is dropped when no screen watches it.
///
/// Copied from [DrawingSearchController].
@ProviderFor(DrawingSearchController)
const drawingSearchControllerProvider = DrawingSearchControllerFamily();

/// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
/// distinct query (family key); it is dropped when no screen watches it.
///
/// Copied from [DrawingSearchController].
class DrawingSearchControllerFamily
    extends Family<AsyncValue<PagedState<DrawingSummary>>> {
  /// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
  /// distinct query (family key); it is dropped when no screen watches it.
  ///
  /// Copied from [DrawingSearchController].
  const DrawingSearchControllerFamily();

  /// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
  /// distinct query (family key); it is dropped when no screen watches it.
  ///
  /// Copied from [DrawingSearchController].
  DrawingSearchControllerProvider call(DrawingSearchQuery query) {
    return DrawingSearchControllerProvider(query);
  }

  @override
  DrawingSearchControllerProvider getProviderOverride(
    covariant DrawingSearchControllerProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'drawingSearchControllerProvider';
}

/// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
/// distinct query (family key); it is dropped when no screen watches it.
///
/// Copied from [DrawingSearchController].
class DrawingSearchControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          DrawingSearchController,
          PagedState<DrawingSummary>
        > {
  /// Cursor-paginated results of one [DrawingSearchQuery]. One instance per
  /// distinct query (family key); it is dropped when no screen watches it.
  ///
  /// Copied from [DrawingSearchController].
  DrawingSearchControllerProvider(DrawingSearchQuery query)
    : this._internal(
        () => DrawingSearchController()..query = query,
        from: drawingSearchControllerProvider,
        name: r'drawingSearchControllerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$drawingSearchControllerHash,
        dependencies: DrawingSearchControllerFamily._dependencies,
        allTransitiveDependencies:
            DrawingSearchControllerFamily._allTransitiveDependencies,
        query: query,
      );

  DrawingSearchControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final DrawingSearchQuery query;

  @override
  FutureOr<PagedState<DrawingSummary>> runNotifierBuild(
    covariant DrawingSearchController notifier,
  ) {
    return notifier.build(query);
  }

  @override
  Override overrideWith(DrawingSearchController Function() create) {
    return ProviderOverride(
      origin: this,
      override: DrawingSearchControllerProvider._internal(
        () => create()..query = query,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    DrawingSearchController,
    PagedState<DrawingSummary>
  >
  createElement() {
    return _DrawingSearchControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DrawingSearchControllerProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DrawingSearchControllerRef
    on AutoDisposeAsyncNotifierProviderRef<PagedState<DrawingSummary>> {
  /// The parameter `query` of this provider.
  DrawingSearchQuery get query;
}

class _DrawingSearchControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          DrawingSearchController,
          PagedState<DrawingSummary>
        >
    with DrawingSearchControllerRef {
  _DrawingSearchControllerProviderElement(super.provider);

  @override
  DrawingSearchQuery get query =>
      (origin as DrawingSearchControllerProvider).query;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
