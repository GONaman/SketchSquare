// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$uploadFlowHash() => r'0a65307151b789aeb67aa59997f437051ad18f70';

/// Drives the multi-step upload flow: form, draft persistence, presigned
/// sheet uploads with progress/retry, publish and processing-status polling.
///
/// Copied from [UploadFlow].
@ProviderFor(UploadFlow)
final uploadFlowProvider =
    NotifierProvider<UploadFlow, UploadFlowState>.internal(
      UploadFlow.new,
      name: r'uploadFlowProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$uploadFlowHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UploadFlow = Notifier<UploadFlowState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
