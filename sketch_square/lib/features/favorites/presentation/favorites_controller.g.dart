// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoritesControllerHash() =>
    r'205e9adb79d0995d6a8882f98865682f81fa9db6';

/// The user's favorite drawings (`GET /me/favorites`), newest favorite first.
///
/// Copied from [FavoritesController].
@ProviderFor(FavoritesController)
final favoritesControllerProvider = AsyncNotifierProvider<
  FavoritesController,
  PagedState<DrawingSummary>
>.internal(
  FavoritesController.new,
  name: r'favoritesControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoritesControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoritesController = AsyncNotifier<PagedState<DrawingSummary>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
