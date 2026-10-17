// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartCountHash() => r'c33bf80fc0b6ebebbba9437d5c577c873d5f7f9b';

/// Number of items for badges; 0 while loading or on error.
///
/// Copied from [cartCount].
@ProviderFor(cartCount)
final cartCountProvider = AutoDisposeProvider<int>.internal(
  cartCount,
  name: r'cartCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartCountRef = AutoDisposeProviderRef<int>;
String _$cartControllerHash() => r'b298316624be33f8970dcf3f5842edf696cba2d7';

/// The signed-in user's basket. Mutations throw `ApiException` to the caller
/// (so screens can show the server's message) and leave the state untouched.
///
/// Copied from [CartController].
@ProviderFor(CartController)
final cartControllerProvider =
    AsyncNotifierProvider<CartController, Cart>.internal(
      CartController.new,
      name: r'cartControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$cartControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CartController = AsyncNotifier<Cart>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
