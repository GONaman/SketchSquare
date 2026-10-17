// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletControllerHash() => r'049cc27e7833cdc88514fb633d48d7ae0fd0f604';

/// Balance, limits and the payout bank account (`GET /wallet`).
///
/// Copied from [WalletController].
@ProviderFor(WalletController)
final walletControllerProvider =
    AsyncNotifierProvider<WalletController, WalletSummary>.internal(
      WalletController.new,
      name: r'walletControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$walletControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WalletController = AsyncNotifier<WalletSummary>;
String _$ledgerControllerHash() => r'137cc380e2d72580d3ccc799bafa4dd8049ce6fe';

/// Wallet transactions, newest first.
///
/// Copied from [LedgerController].
@ProviderFor(LedgerController)
final ledgerControllerProvider =
    AsyncNotifierProvider<LedgerController, PagedState<LedgerEntry>>.internal(
      LedgerController.new,
      name: r'ledgerControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$ledgerControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LedgerController = AsyncNotifier<PagedState<LedgerEntry>>;
String _$withdrawalsControllerHash() =>
    r'edd0660a1406f7cf0e3d8b42d075b693db94928f';

/// Payout history (`GET /wallet/withdrawals`), newest first.
///
/// Copied from [WithdrawalsController].
@ProviderFor(WithdrawalsController)
final withdrawalsControllerProvider = AsyncNotifierProvider<
  WithdrawalsController,
  PagedState<Withdrawal>
>.internal(
  WithdrawalsController.new,
  name: r'withdrawalsControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$withdrawalsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WithdrawalsController = AsyncNotifier<PagedState<Withdrawal>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
