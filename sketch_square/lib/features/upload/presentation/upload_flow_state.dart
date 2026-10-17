import 'package:freezed_annotation/freezed_annotation.dart';

import '../../drawings/domain/drawing_summary.dart';
import '../domain/contribution_status.dart';
import '../domain/drawing_form.dart';
import '../domain/drawing_form_validators.dart';
import '../domain/sheet_file_rules.dart';
import '../domain/sheet_upload_target.dart';
import '../domain/upload_repository.dart';

part 'upload_flow_state.freezed.dart';

enum UploadStep {
  details('Details'),
  sheets('Sheets'),
  pricing('Pricing'),
  review('Review');

  const UploadStep(this.label);
  final String label;
}

enum SheetUploadStatus { queued, uploading, registering, done, failed }

/// A sheet in the upload list: either picked locally (has a [file]) or
/// restored from the server draft (already [SheetUploadStatus.done]).
@freezed
abstract class SheetItem with _$SheetItem {
  const SheetItem._();

  const factory SheetItem({
    required String localId,
    required String name,
    required int sizeBytes,
    @Default(SheetType.architectural) SheetType type,
    @Default(false) bool isPreview,
    @Default(SheetUploadStatus.queued) SheetUploadStatus status,
    // 0..1 while uploading.
    @Default(0) double progress,
    String? serverSheetId,
    // Kept after a successful PUT so a failed registration retries without re-uploading.
    String? objectKey,
    String? error,
    PickedSheetFile? file,
  }) = _SheetItem;

  bool get isDone => status == SheetUploadStatus.done;
  bool get isFailed => status == SheetUploadStatus.failed;
  bool get isBusy =>
      status == SheetUploadStatus.uploading ||
      status == SheetUploadStatus.registering;
  bool get canBePreview => SheetFileRules.canBePreview(name);
}

enum PublishPhase {
  idle,
  publishing,
  processing,
  published,
  underReview,
  failed,
}

@freezed
abstract class UploadFlowState with _$UploadFlowState {
  const UploadFlowState._();

  const factory UploadFlowState({
    @Default(false) bool loaded,
    @Default(UploadStep.details) UploadStep step,
    @Default(DrawingForm()) DrawingForm form,
    String? draftId,
    @Default(<SheetItem>[]) List<SheetItem> sheets,
    @Default(<CategoryRef>[]) List<CategoryRef> categories,
    String? categoriesError,
    // Show validation messages (after the user tried to continue).
    @Default(false) bool showErrors,
    @Default(false) bool saving,
    // Last save/restore/publish error to display in a banner.
    String? error,
    // Transient notices, e.g. files rejected by client-side validation.
    @Default(<String>[]) List<String> notices,
    @Default(PublishPhase.idle) PublishPhase phase,
    String? failureReason,
    // Polling gave up (offline / timeout) but the server may still be working.
    @Default(false) bool pollStalled,
    // Contribution rule (8.3); null until loaded or if it couldn't be fetched.
    ContributionStatus? contribution,
  }) = _UploadFlowState;

  int get previewCount => sheets.where((s) => s.isPreview).length;
  bool get hasPendingUploads => sheets.any((s) => !s.isDone);
  bool get hasActiveWork =>
      sheets.any((s) => s.isBusy || s.status == SheetUploadStatus.queued);

  Map<String, String> get detailErrors => DrawingFormValidators.details(form);

  /// Paid listing blocked by the contribution rule (needs more free drawings).
  bool get paidBlockedByContribution =>
      !form.isFree && contribution != null && !contribution!.canPublishPaid;

  Map<String, String> get pricingErrors => {
    ...DrawingFormValidators.pricing(form),
    if (paidBlockedByContribution) 'contribution': contribution!.blockedMessage,
  };

  /// Message for the sheets step, or null if it is complete.
  String? get sheetsError {
    if (sheets.isEmpty) return 'Add at least one sheet';
    if (sheets.any((s) => s.isFailed)) {
      return 'Retry or remove the sheets that failed to upload';
    }
    if (hasPendingUploads) return 'Wait for uploads to finish';
    final previews = previewCount;
    if (previews < 1) return 'Mark 1–2 sheets as previews';
    if (previews > SheetFileRules.maxPreviewSheets) {
      return 'Choose at most ${SheetFileRules.maxPreviewSheets} preview sheets';
    }
    return null;
  }

  /// Everything that prevents publishing right now (empty = ready).
  List<String> get publishBlockers => [
    ...detailErrors.values,
    ...pricingErrors.values,
    if (sheetsError case final e?) e,
  ];

  bool get isProcessing =>
      phase == PublishPhase.publishing || phase == PublishPhase.processing;

  bool get isFinished =>
      phase == PublishPhase.published || phase == PublishPhase.underReview;

  bool get locked => isProcessing || isFinished;
}

/// Maps a server status to the publish phase used when resuming a draft.
PublishPhase? phaseForStatus(DrawingStatus status) => switch (status) {
  DrawingStatus.processing => PublishPhase.processing,
  DrawingStatus.published => PublishPhase.published,
  DrawingStatus.underReview => PublishPhase.underReview,
  DrawingStatus.failed => PublishPhase.failed,
  _ => null,
};
