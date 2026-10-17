// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$drawingsRepositoryHash() =>
    r'b01542d4b4ef4c264264e7111c7fb3232cacd4fb';

/// See also [drawingsRepository].
@ProviderFor(drawingsRepository)
final drawingsRepositoryProvider = Provider<DrawingsRepository>.internal(
  drawingsRepository,
  name: r'drawingsRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$drawingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DrawingsRepositoryRef = ProviderRef<DrawingsRepository>;
String _$drawingActionsRepositoryHash() =>
    r'97dd810bab72318b08379570cf0c997fffd2fbff';

/// See also [drawingActionsRepository].
@ProviderFor(drawingActionsRepository)
final drawingActionsRepositoryProvider =
    Provider<DrawingActionsRepository>.internal(
      drawingActionsRepository,
      name: r'drawingActionsRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$drawingActionsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DrawingActionsRepositoryRef = ProviderRef<DrawingActionsRepository>;
String _$categoriesHash() => r'2dac40161bf06606105a4448e7a866e90826d2a6';

/// Active categories for chips and the filter sheet. Cached for the session.
///
/// Copied from [categories].
@ProviderFor(categories)
final categoriesProvider = FutureProvider<List<CategoryRef>>.internal(
  categories,
  name: r'categoriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$categoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoriesRef = FutureProviderRef<List<CategoryRef>>;
String _$citiesHash() => r'44f0d8d37e5843d2535a07adf1d1712eff2a73bd';

/// Cities that have published drawings (filter sheet, Featured city picker).
///
/// Copied from [cities].
@ProviderFor(cities)
final citiesProvider = FutureProvider<List<CityCount>>.internal(
  cities,
  name: r'citiesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$citiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CitiesRef = FutureProviderRef<List<CityCount>>;
String _$drawingDetailHash() => r'3a3a4bd13dcf1ebc3a2b17cfe1c9731786fad735';

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

/// See also [drawingDetail].
@ProviderFor(drawingDetail)
const drawingDetailProvider = DrawingDetailFamily();

/// See also [drawingDetail].
class DrawingDetailFamily extends Family<AsyncValue<DrawingDetail>> {
  /// See also [drawingDetail].
  const DrawingDetailFamily();

  /// See also [drawingDetail].
  DrawingDetailProvider call(String id) {
    return DrawingDetailProvider(id);
  }

  @override
  DrawingDetailProvider getProviderOverride(
    covariant DrawingDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'drawingDetailProvider';
}

/// See also [drawingDetail].
class DrawingDetailProvider extends AutoDisposeFutureProvider<DrawingDetail> {
  /// See also [drawingDetail].
  DrawingDetailProvider(String id)
    : this._internal(
        (ref) => drawingDetail(ref as DrawingDetailRef, id),
        from: drawingDetailProvider,
        name: r'drawingDetailProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$drawingDetailHash,
        dependencies: DrawingDetailFamily._dependencies,
        allTransitiveDependencies:
            DrawingDetailFamily._allTransitiveDependencies,
        id: id,
      );

  DrawingDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<DrawingDetail> Function(DrawingDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DrawingDetailProvider._internal(
        (ref) => create(ref as DrawingDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DrawingDetail> createElement() {
    return _DrawingDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DrawingDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DrawingDetailRef on AutoDisposeFutureProviderRef<DrawingDetail> {
  /// The parameter `id` of this provider.
  String get id;
}

class _DrawingDetailProviderElement
    extends AutoDisposeFutureProviderElement<DrawingDetail>
    with DrawingDetailRef {
  _DrawingDetailProviderElement(super.provider);

  @override
  String get id => (origin as DrawingDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
