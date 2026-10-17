// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadControllerHash() =>
    r'8b3f86dc6e19757f99c17d076b88709502edbf21';

/// Download state per sheet id. A sheet downloaded in this session is served
/// from the local file (no second presigned URL, no second quota hit).
///
/// Copied from [DownloadController].
@ProviderFor(DownloadController)
final downloadControllerProvider =
    NotifierProvider<DownloadController, Map<String, DownloadState>>.internal(
      DownloadController.new,
      name: r'downloadControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$downloadControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DownloadController = Notifier<Map<String, DownloadState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
