// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$checkoutControllerHash() =>
    r'3d17522d4665c18dbfe5d0c61a36303d0ae70be0';

/// Drives basket -> order -> payment -> confirmation. In stub mode
/// (`razorpayKeyId == "stub"`) the payment sheet is skipped and the backend's
/// `/checkout/stub-complete` simulates the captured-payment webhook.
///
/// Copied from [CheckoutController].
@ProviderFor(CheckoutController)
final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>.internal(
      CheckoutController.new,
      name: r'checkoutControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$checkoutControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CheckoutController = Notifier<CheckoutState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
