// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminRepositoryHash() => r'd08b3a3ee158da2bfd4caaaaa011191293722d56';

/// See also [adminRepository].
@ProviderFor(adminRepository)
final adminRepositoryProvider = Provider<AdminRepository>.internal(
  adminRepository,
  name: r'adminRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminRepositoryRef = ProviderRef<AdminRepository>;
String _$documentLauncherHash() => r'cd13f505762c83445f0589fafa0837ce7d1ec0a7';

/// See also [documentLauncher].
@ProviderFor(documentLauncher)
final documentLauncherProvider = Provider<DocumentLauncher>.internal(
  documentLauncher,
  name: r'documentLauncherProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentLauncherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentLauncherRef = ProviderRef<DocumentLauncher>;
String _$adminVerificationHash() => r'0c49a38a9601f7d0375dc814ab6abdcb7713930b';

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

/// See also [adminVerification].
@ProviderFor(adminVerification)
const adminVerificationProvider = AdminVerificationFamily();

/// See also [adminVerification].
class AdminVerificationFamily extends Family<AsyncValue<AdminVerification>> {
  /// See also [adminVerification].
  const AdminVerificationFamily();

  /// See also [adminVerification].
  AdminVerificationProvider call(String id) {
    return AdminVerificationProvider(id);
  }

  @override
  AdminVerificationProvider getProviderOverride(
    covariant AdminVerificationProvider provider,
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
  String? get name => r'adminVerificationProvider';
}

/// See also [adminVerification].
class AdminVerificationProvider
    extends AutoDisposeFutureProvider<AdminVerification> {
  /// See also [adminVerification].
  AdminVerificationProvider(String id)
    : this._internal(
        (ref) => adminVerification(ref as AdminVerificationRef, id),
        from: adminVerificationProvider,
        name: r'adminVerificationProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$adminVerificationHash,
        dependencies: AdminVerificationFamily._dependencies,
        allTransitiveDependencies:
            AdminVerificationFamily._allTransitiveDependencies,
        id: id,
      );

  AdminVerificationProvider._internal(
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
    FutureOr<AdminVerification> Function(AdminVerificationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminVerificationProvider._internal(
        (ref) => create(ref as AdminVerificationRef),
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
  AutoDisposeFutureProviderElement<AdminVerification> createElement() {
    return _AdminVerificationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminVerificationProvider && other.id == id;
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
mixin AdminVerificationRef on AutoDisposeFutureProviderRef<AdminVerification> {
  /// The parameter `id` of this provider.
  String get id;
}

class _AdminVerificationProviderElement
    extends AutoDisposeFutureProviderElement<AdminVerification>
    with AdminVerificationRef {
  _AdminVerificationProviderElement(super.provider);

  @override
  String get id => (origin as AdminVerificationProvider).id;
}

String _$pendingVerificationsHash() =>
    r'31df89eace7325cb3cc06321b3b5fd14fcc696d5';

/// PENDING verification requests, cursor-paginated.
///
/// Copied from [PendingVerifications].
@ProviderFor(PendingVerifications)
final pendingVerificationsProvider = AutoDisposeAsyncNotifierProvider<
  PendingVerifications,
  PagedState<AdminVerification>
>.internal(
  PendingVerifications.new,
  name: r'pendingVerificationsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingVerificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingVerifications =
    AutoDisposeAsyncNotifier<PagedState<AdminVerification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
