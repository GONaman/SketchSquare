// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'architects_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$architectsRepositoryHash() =>
    r'882867c148b74246bb72e92b05e9e8b6cd5157d3';

/// See also [architectsRepository].
@ProviderFor(architectsRepository)
final architectsRepositoryProvider = Provider<ArchitectsRepository>.internal(
  architectsRepository,
  name: r'architectsRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$architectsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchitectsRepositoryRef = ProviderRef<ArchitectsRepository>;
String _$topArchitectsHash() => r'baf5c3f4801d5cd49ffb32112d9b3eb45cf9f867';

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

/// See also [topArchitects].
@ProviderFor(topArchitects)
const topArchitectsProvider = TopArchitectsFamily();

/// See also [topArchitects].
class TopArchitectsFamily extends Family<AsyncValue<List<TopArchitect>>> {
  /// See also [topArchitects].
  const TopArchitectsFamily();

  /// See also [topArchitects].
  TopArchitectsProvider call(String? city) {
    return TopArchitectsProvider(city);
  }

  @override
  TopArchitectsProvider getProviderOverride(
    covariant TopArchitectsProvider provider,
  ) {
    return call(provider.city);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topArchitectsProvider';
}

/// See also [topArchitects].
class TopArchitectsProvider
    extends AutoDisposeFutureProvider<List<TopArchitect>> {
  /// See also [topArchitects].
  TopArchitectsProvider(String? city)
    : this._internal(
        (ref) => topArchitects(ref as TopArchitectsRef, city),
        from: topArchitectsProvider,
        name: r'topArchitectsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$topArchitectsHash,
        dependencies: TopArchitectsFamily._dependencies,
        allTransitiveDependencies:
            TopArchitectsFamily._allTransitiveDependencies,
        city: city,
      );

  TopArchitectsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.city,
  }) : super.internal();

  final String? city;

  @override
  Override overrideWith(
    FutureOr<List<TopArchitect>> Function(TopArchitectsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TopArchitectsProvider._internal(
        (ref) => create(ref as TopArchitectsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        city: city,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TopArchitect>> createElement() {
    return _TopArchitectsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopArchitectsProvider && other.city == city;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, city.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopArchitectsRef on AutoDisposeFutureProviderRef<List<TopArchitect>> {
  /// The parameter `city` of this provider.
  String? get city;
}

class _TopArchitectsProviderElement
    extends AutoDisposeFutureProviderElement<List<TopArchitect>>
    with TopArchitectsRef {
  _TopArchitectsProviderElement(super.provider);

  @override
  String? get city => (origin as TopArchitectsProvider).city;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
