import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../data/upload_providers.dart';
import '../domain/draft_store.dart';
import '../domain/drawing_form.dart';
import '../domain/drawing_record.dart';
import '../domain/sheet_file_rules.dart';
import '../domain/sheet_upload_target.dart';
import '../domain/upload_repository.dart';
import 'upload_flow_state.dart';

part 'upload_flow_controller.g.dart';

enum DraftSaveResult { synced, localOnly, failed }

/// Drives the multi-step upload flow: form, draft persistence, presigned
/// sheet uploads with progress/retry, publish and processing-status polling.
@Riverpod(keepAlive: true)
class UploadFlow extends _$UploadFlow {
  static const pollInterval = Duration(seconds: 2);
  static const maxPollAttempts = 150; // ~5 minutes
  static const maxConsecutivePollErrors = 5;

  int _localCounter = 0;
  int _generation = 0;
  bool _pumping = false;
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  UploadFlowState build() {
    ref.onDispose(() {
      _generation++;
      for (final t in _cancelTokens.values) {
        t.cancel();
      }
    });
    return const UploadFlowState();
  }

  UploadRepository get _repo => ref.read(uploadRepositoryProvider);
  DraftStore get _store => ref.read(draftStoreProvider);

  // ---------------------------------------------------------------- loading

  /// Restores the previous session (or [resumeDraftId]) and loads categories.
  /// Safe to call every time the Upload screen appears.
  Future<void> ensureLoaded({String? resumeDraftId}) async {
    final alreadyActive =
        state.loaded &&
        (resumeDraftId == null || resumeDraftId == state.draftId);
    if (alreadyActive) {
      if (state.categories.isEmpty) unawaited(loadCategories());
      return;
    }

    _generation++;
    final gen = _generation;
    for (final t in _cancelTokens.values) {
      t.cancel();
    }
    _cancelTokens.clear();
    state = UploadFlowState(categories: state.categories);
    unawaited(loadCategories());

    StoredDraft? stored;
    try {
      stored = await _store.load();
    } catch (_) {
      stored = null;
    }
    if (gen != _generation) return;

    final draftId = resumeDraftId ?? stored?.draftId;
    final localForm =
        (stored != null && stored.draftId == draftId) ? stored.form : null;

    if (draftId == null) {
      state = state.copyWith(
        loaded: true,
        form: stored?.form ?? const DrawingForm(),
        step: _stepAt(stored?.stepIndex ?? 0),
      );
      return;
    }

    try {
      final record = await _repo.getDrawing(draftId);
      if (gen != _generation) return;
      _hydrate(record, localForm: localForm, stored: stored);
    } on ApiException catch (e) {
      if (gen != _generation) return;
      if (e.code == ApiErrorCodes.notFound ||
          e.code == ApiErrorCodes.forbidden) {
        // The draft is gone (deleted elsewhere): keep what was typed locally.
        state = state.copyWith(
          loaded: true,
          form: localForm ?? const DrawingForm(),
          step: _stepAt(stored?.stepIndex ?? 0),
        );
        _persist();
      } else {
        state = state.copyWith(
          loaded: true,
          draftId: draftId,
          form: localForm ?? const DrawingForm(),
          step: _stepAt(stored?.stepIndex ?? 0),
          error: "Couldn't load your draft from the server. ${e.message}",
        );
      }
    }
  }

  void _hydrate(
    DrawingRecord record, {
    DrawingForm? localForm,
    StoredDraft? stored,
  }) {
    final phase = phaseForStatus(record.status);
    if (record.status == DrawingStatus.removed) {
      unawaited(_store.clear());
      state = UploadFlowState(categories: state.categories, loaded: true);
      return;
    }
    final sheets = [
      for (final s in record.sheets)
        SheetItem(
          localId: _nextLocalId(),
          name: s.fileName,
          sizeBytes: s.sizeBytes,
          type: s.type,
          isPreview: s.isPreview,
          status: SheetUploadStatus.done,
          progress: 1,
          serverSheetId: s.id,
        ),
    ];
    state = state.copyWith(
      loaded: true,
      draftId: record.id,
      form: phase != null ? record.toForm() : (localForm ?? record.toForm()),
      sheets: sheets,
      step: phase != null ? UploadStep.review : _stepAt(stored?.stepIndex ?? 0),
      phase: phase ?? PublishPhase.idle,
      failureReason: record.failureReason,
    );
    if (phase == PublishPhase.published || phase == PublishPhase.underReview) {
      unawaited(_store.clear());
    } else {
      _persist();
    }
    if (phase == PublishPhase.processing) unawaited(_poll());
  }

  Future<void> loadCategories() async {
    try {
      final cats = await _repo.fetchCategories();
      state = state.copyWith(categories: cats, categoriesError: null);
    } on ApiException catch (e) {
      state = state.copyWith(categoriesError: e.message);
    }
  }

  UploadStep _stepAt(int i) =>
      UploadStep.values[i.clamp(0, UploadStep.values.length - 1)];

  String _nextLocalId() => 'local-${_localCounter++}';

  void _persist() {
    if (state.isFinished) return;
    unawaited(
      _store
          .save(
            StoredDraft(
              draftId: state.draftId,
              form: state.form,
              stepIndex: state.step.index,
            ),
          )
          .catchError((_) {}),
    );
  }

  /// Discards the finished/abandoned flow and starts a blank one.
  Future<void> startNew() async {
    _generation++;
    for (final t in _cancelTokens.values) {
      t.cancel();
    }
    _cancelTokens.clear();
    await _store.clear();
    state = UploadFlowState(categories: state.categories, loaded: true);
  }

  void dismissError() => state = state.copyWith(error: null);
  void dismissNotices() => state = state.copyWith(notices: const []);

  // ------------------------------------------------------------------- form

  void updateForm(DrawingForm Function(DrawingForm) update) {
    if (state.locked) return;
    state = state.copyWith(form: update(state.form));
    _persist();
  }

  // ------------------------------------------------------------- navigation

  void goToStep(UploadStep step) {
    if (state.locked) return;
    // Jumping forward is only allowed to steps whose predecessors are valid.
    if (step.index > state.step.index && !_canEnter(step)) {
      state = state.copyWith(showErrors: true);
      return;
    }
    state = state.copyWith(step: step, showErrors: false);
    _persist();
  }

  bool _canEnter(UploadStep step) {
    for (final s in UploadStep.values) {
      if (s.index >= step.index) break;
      if (_stepError(s) != null) return false;
    }
    return true;
  }

  String? _stepError(UploadStep s) => switch (s) {
    UploadStep.details => state.detailErrors.isEmpty ? null : 'details',
    UploadStep.sheets => state.sheetsError,
    UploadStep.pricing => state.pricingErrors.isEmpty ? null : 'pricing',
    UploadStep.review => null,
  };

  void back() {
    if (state.locked || state.step.index == 0) return;
    state = state.copyWith(
      step: UploadStep.values[state.step.index - 1],
      showErrors: false,
    );
    _persist();
  }

  /// Validates the current step and advances; the details and pricing steps
  /// also sync the draft to the server so sheets/publish can reference it.
  Future<void> next() async {
    if (state.locked || state.saving) return;
    if (_stepError(state.step) != null) {
      state = state.copyWith(showErrors: true);
      return;
    }
    if (state.step == UploadStep.review) return;
    if (state.step == UploadStep.details || state.step == UploadStep.pricing) {
      final result = await saveDraft();
      if (result == DraftSaveResult.failed) return;
    }
    state = state.copyWith(
      step: UploadStep.values[state.step.index + 1],
      showErrors: false,
    );
    _persist();
    if (state.step == UploadStep.sheets) unawaited(_pump());
  }

  // ------------------------------------------------------------------ draft

  /// Creates or updates the server draft. Returns [DraftSaveResult.localOnly]
  /// when the form is not valid enough to sync (it is still stored on device).
  Future<DraftSaveResult> saveDraft() async {
    _persist();
    if (state.detailErrors.isNotEmpty) {
      state = state.copyWith(showErrors: true);
      return DraftSaveResult.localOnly;
    }
    state = state.copyWith(saving: true, error: null);
    final gen = _generation;
    try {
      final id = state.draftId;
      final record =
          id == null
              ? await _repo.createDraft(state.form)
              : await _repo.updateDraft(id, state.form);
      if (gen != _generation) return DraftSaveResult.failed;
      state = state.copyWith(saving: false, draftId: record.id);
      _persist();
      return DraftSaveResult.synced;
    } on ApiException catch (e) {
      if (gen != _generation) return DraftSaveResult.failed;
      state = state.copyWith(
        saving: false,
        error: "Couldn't save your draft. ${e.message}",
      );
      return DraftSaveResult.failed;
    }
  }

  // ----------------------------------------------------------------- sheets

  /// Opens the picker and queues the accepted files for upload.
  Future<void> pickSheets() async {
    if (state.locked) return;
    final picked = await ref.read(sheetPickerProvider).pickSheets();
    addFiles(picked);
  }

  void addFiles(List<PickedSheetFile> files) {
    if (state.locked || files.isEmpty) return;
    final notices = <String>[];
    final items = [...state.sheets];
    for (final f in files) {
      final problem = SheetFileRules.validate(f.name, f.sizeBytes);
      if (problem != null) {
        notices.add('${f.name}: $problem');
        continue;
      }
      if (items.any((s) => s.name == f.name && s.sizeBytes == f.sizeBytes)) {
        notices.add('${f.name} is already added.');
        continue;
      }
      final canPreview = SheetFileRules.canBePreview(f.name);
      final previews = items.where((s) => s.isPreview).length;
      items.add(
        SheetItem(
          localId: _nextLocalId(),
          name: f.name,
          sizeBytes: f.sizeBytes,
          file: f,
          // First previewable sheet is a sensible default preview.
          isPreview: canPreview && previews == 0,
        ),
      );
    }
    state = state.copyWith(sheets: items, notices: notices);
    unawaited(_pump());
  }

  SheetItem? _item(String localId) =>
      state.sheets.where((s) => s.localId == localId).firstOrNull;

  void _patchItem(String localId, SheetItem Function(SheetItem) update) {
    state = state.copyWith(
      sheets: [
        for (final s in state.sheets) s.localId == localId ? update(s) : s,
      ],
    );
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        final next =
            state.sheets
                .where((s) => s.status == SheetUploadStatus.queued)
                .firstOrNull;
        if (next == null) break;
        await _processSheet(next.localId);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _processSheet(String localId) async {
    final gen = _generation;
    var item = _item(localId);
    if (item == null) return;

    _patchItem(
      localId,
      (s) => s.copyWith(
        status: SheetUploadStatus.uploading,
        progress: s.objectKey != null ? 1 : 0,
        error: null,
      ),
    );

    try {
      if (state.draftId == null) {
        final saved = await saveDraft();
        if (saved != DraftSaveResult.synced) {
          throw const ApiException(
            code: ApiErrorCodes.validation,
            message: 'Fill in the drawing details before uploading sheets.',
          );
        }
      }
      final draftId = state.draftId!;

      if (item.objectKey == null) {
        final file = item.file!;
        final target = await _repo.requestSheetUpload(
          draftId,
          fileName: item.name,
          contentType: SheetFileRules.contentTypeFor(item.name)!,
          sizeBytes: item.sizeBytes,
        );
        final token = CancelToken();
        _cancelTokens[localId] = token;
        await ref
            .read(sheetUploaderProvider)
            .upload(
              target,
              file,
              cancelToken: token,
              onProgress: (sent, total) {
                if (gen != _generation || _item(localId) == null) return;
                final t = total > 0 ? total : item!.sizeBytes;
                _patchItem(
                  localId,
                  (s) => s.copyWith(progress: (sent / t).clamp(0.0, 1.0)),
                );
              },
            );
        _cancelTokens.remove(localId);
        if (gen != _generation || _item(localId) == null) return;
        _patchItem(
          localId,
          (s) => s.copyWith(
            objectKey: target.objectKey,
            progress: 1,
            status: SheetUploadStatus.registering,
          ),
        );
      } else {
        _patchItem(
          localId,
          (s) => s.copyWith(status: SheetUploadStatus.registering),
        );
      }

      // Re-read: the seller may have changed type/preview while uploading.
      item = _item(localId);
      if (item == null) return;
      final sheet = await _repo.registerSheet(
        draftId,
        type: item.type,
        objectKey: item.objectKey!,
        isPreview: item.isPreview,
        fileName: item.name,
        sizeBytes: item.sizeBytes,
      );
      if (gen != _generation || _item(localId) == null) return;
      _patchItem(
        localId,
        (s) => s.copyWith(
          status: SheetUploadStatus.done,
          serverSheetId: sheet.id,
          error: null,
        ),
      );
    } on ApiException catch (e) {
      _cancelTokens.remove(localId);
      if (gen != _generation || _item(localId) == null) return;
      if (e.code == ApiErrorCodes.cancelled) return;
      _patchItem(
        localId,
        (s) => s.copyWith(status: SheetUploadStatus.failed, error: e.message),
      );
    }
  }

  void retrySheet(String localId) {
    final item = _item(localId);
    if (item == null || !item.isFailed || state.locked) return;
    _patchItem(
      localId,
      (s) => s.copyWith(status: SheetUploadStatus.queued, error: null),
    );
    unawaited(_pump());
  }

  Future<void> removeSheet(String localId) async {
    final item = _item(localId);
    if (item == null || state.locked) return;
    _cancelTokens.remove(localId)?.cancel();
    final previous = state.sheets;
    state = state.copyWith(
      sheets: [
        for (final s in state.sheets)
          if (s.localId != localId) s,
      ],
    );
    final serverId = item.serverSheetId;
    if (serverId != null && state.draftId != null) {
      try {
        await _repo.deleteSheet(state.draftId!, serverId);
      } on ApiException catch (e) {
        state = state.copyWith(
          sheets: previous,
          error: "Couldn't remove ${item.name}. ${e.message}",
        );
      }
    }
  }

  Future<void> setSheetType(String localId, SheetType type) async {
    final item = _item(localId);
    if (item == null || state.locked || item.type == type) return;
    _patchItem(localId, (s) => s.copyWith(type: type));
    await _syncSheet(item, type: type);
  }

  Future<void> togglePreview(String localId) async {
    final item = _item(localId);
    if (item == null || state.locked) return;
    final makePreview = !item.isPreview;
    if (makePreview) {
      if (!item.canBePreview) {
        state = state.copyWith(
          notices: ['${item.name} is a CAD file and cannot be a preview.'],
        );
        return;
      }
      if (state.previewCount >= SheetFileRules.maxPreviewSheets) {
        state = state.copyWith(
          notices: [
            'You can pick at most ${SheetFileRules.maxPreviewSheets} preview sheets.',
          ],
        );
        return;
      }
    }
    _patchItem(localId, (s) => s.copyWith(isPreview: makePreview));
    await _syncSheet(item, isPreview: makePreview);
  }

  /// Pushes a type/preview change for an already-registered sheet; rolls the
  /// local change back if the server rejects it.
  Future<void> _syncSheet(
    SheetItem before, {
    SheetType? type,
    bool? isPreview,
  }) async {
    final serverId = before.serverSheetId;
    final draftId = state.draftId;
    if (serverId == null || draftId == null) return;
    try {
      await _repo.updateSheet(
        draftId,
        serverId,
        type: type,
        isPreview: isPreview,
      );
    } on ApiException catch (e) {
      _patchItem(
        before.localId,
        (s) => s.copyWith(type: before.type, isPreview: before.isPreview),
      );
      state = state.copyWith(error: "Couldn't update the sheet. ${e.message}");
    }
  }

  // ---------------------------------------------------------------- publish

  Future<void> publish() async {
    if (state.locked || state.saving) return;
    if (state.publishBlockers.isNotEmpty) {
      state = state.copyWith(showErrors: true);
      return;
    }
    final saved = await saveDraft();
    if (saved != DraftSaveResult.synced) return;
    await _requestPublish();
  }

  /// Re-submits a drawing whose processing failed.
  Future<void> retryPublish() async {
    if (state.phase != PublishPhase.failed || state.draftId == null) return;
    await _requestPublish();
  }

  /// After a failed processing run: back to the editable review step.
  void editAfterFailure() {
    if (state.phase != PublishPhase.failed) return;
    state = state.copyWith(
      phase: PublishPhase.idle,
      step: UploadStep.details,
      failureReason: null,
    );
    _persist();
  }

  Future<void> _requestPublish() async {
    final gen = _generation;
    state = state.copyWith(
      phase: PublishPhase.publishing,
      error: null,
      failureReason: null,
      pollStalled: false,
    );
    try {
      final status = await _repo.publish(state.draftId!);
      if (gen != _generation) return;
      state = state.copyWith(phase: PublishPhase.processing);
      if (status == DrawingStatus.published) {
        _finish(PublishPhase.published);
      } else {
        unawaited(_poll());
      }
    } on ApiException catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(phase: PublishPhase.idle, error: e.message);
    }
  }

  /// Retry polling after it stalled.
  Future<void> resumePolling() async {
    if (state.phase != PublishPhase.processing || state.draftId == null) return;
    state = state.copyWith(pollStalled: false);
    await _poll();
  }

  Future<void> _poll() async {
    final gen = _generation;
    final id = state.draftId;
    if (id == null) return;
    final delay = ref.read(uploadDelayProvider);
    var consecutiveErrors = 0;
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      await delay(pollInterval);
      if (gen != _generation) return;
      try {
        final record = await _repo.getDrawing(id);
        if (gen != _generation) return;
        consecutiveErrors = 0;
        switch (record.status) {
          case DrawingStatus.published:
            _finish(PublishPhase.published);
            return;
          case DrawingStatus.underReview:
            _finish(PublishPhase.underReview);
            return;
          case DrawingStatus.failed:
            state = state.copyWith(
              phase: PublishPhase.failed,
              failureReason: record.failureReason ?? 'Processing failed.',
            );
            return;
          case DrawingStatus.draft:
          case DrawingStatus.removed:
            state = state.copyWith(
              phase: PublishPhase.idle,
              error: 'This drawing is no longer being processed.',
            );
            return;
          case DrawingStatus.processing:
            break;
        }
      } on ApiException catch (e) {
        if (gen != _generation) return;
        if (e.isUnauthorized ||
            ++consecutiveErrors >= maxConsecutivePollErrors) {
          state = state.copyWith(pollStalled: true);
          return;
        }
      }
    }
    if (gen == _generation) state = state.copyWith(pollStalled: true);
  }

  void _finish(PublishPhase phase) {
    state = state.copyWith(phase: phase, pollStalled: false);
    unawaited(_store.clear());
  }
}
