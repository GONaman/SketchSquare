// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$purchasesControllerHash() =>
    r'eb3c5cd58c1632b74559d5904fb8550b9bc10713';

/// The buyer's library (`GET /me/purchases`), newest first, cursor-paged.
///
/// Copied from [PurchasesController].
@ProviderFor(PurchasesController)
final purchasesControllerProvider = AsyncNotifierProvider<
  PurchasesController,
  PagedState<PurchaseItem>
>.internal(
  PurchasesController.new,
  name: r'purchasesControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchasesControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PurchasesController = AsyncNotifier<PagedState<PurchaseItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
