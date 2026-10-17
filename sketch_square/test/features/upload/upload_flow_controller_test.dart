import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/upload/data/upload_providers.dart';
import 'package:sketch_square/features/upload/domain/draft_store.dart';
import 'package:sketch_square/features/upload/domain/drawing_form.dart';
import 'package:sketch_square/features/upload/domain/sheet_file_rules.dart';
import 'package:sketch_square/features/upload/domain/sheet_upload_target.dart';
import 'package:sketch_square/features/upload/presentation/upload_flow_controller.dart';
import 'package:sketch_square/features/upload/presentation/upload_flow_state.dart';

import 'fakes.dart';

void main() {
  late FakeUploadRepository repo;
  late FakeSheetUploader uploader;
  late FakeSheetPicker picker;
  late InMemoryDraftStore store;
  late ProviderContainer container;

  UploadFlow flow() => container.read(uploadFlowProvider.notifier);
  UploadFlowState st() => container.read(uploadFlowProvider);

  setUp(() {
    repo = FakeUploadRepository();
    uploader = FakeSheetUploader();
    picker = FakeSheetPicker();
    store = InMemoryDraftStore();
    container = ProviderContainer(
      overrides: [
        uploadRepositoryProvider.overrideWithValue(repo),
        sheetUploaderProvider.overrideWithValue(uploader),
        sheetPickerProvider.overrideWithValue(picker),
        draftStoreProvider.overrideWithValue(store),
        uploadDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    container.listen(uploadFlowProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  /// Loads the flow, fills a valid form and advances to the sheets step.
  Future<void> toSheetsStep({bool isFree = true}) async {
    await flow().ensureLoaded();
    flow().updateForm((_) => validForm(isFree: isFree));
    await flow().next();
  }

  Future<void> settle() => pumpEventQueue();

  group('details step', () {
    test(
      'invalid form shows errors, stays put and does not call the API',
      () async {
        await flow().ensureLoaded();
        await flow().next();
        expect(st().step, UploadStep.details);
        expect(st().showErrors, isTrue);
        expect(st().detailErrors, isNotEmpty);
        expect(repo.count('createDraft'), 0);
      },
    );

    test('valid form creates the draft once, then updates it', () async {
      await toSheetsStep();
      expect(st().step, UploadStep.sheets);
      expect(st().draftId, 'd1');
      expect(repo.count('createDraft'), 1);

      flow().back();
      await flow().next();
      expect(repo.count('createDraft'), 1);
      expect(repo.count('updateDraft'), 1);
    });

    test('a save failure keeps the user on the step with a banner', () async {
      repo.failNext('createDraft', apiError(ApiErrorCodes.network, 'offline'));
      await flow().ensureLoaded();
      flow().updateForm((_) => validForm());
      await flow().next();
      expect(st().step, UploadStep.details);
      expect(st().error, contains('offline'));
      expect(st().saving, isFalse);

      await flow().next(); // retry succeeds
      expect(st().step, UploadStep.sheets);
      expect(st().error, isNull);
    });

    test('saveDraft with an incomplete form only stores locally', () async {
      await flow().ensureLoaded();
      flow().updateForm((f) => f.copyWith(title: 'Half done title'));
      expect(await flow().saveDraft(), DraftSaveResult.localOnly);
      expect(repo.count('createDraft'), 0);
      expect(store.stored?.form.title, 'Half done title');
    });
  });

  group('sheet selection', () {
    test(
      'rejects invalid, oversize and duplicate files with notices',
      () async {
        await toSheetsStep();
        flow().addFiles([
          file('virus.exe'),
          file('huge.pdf', size: SheetFileRules.maxBytes + 1),
          file('ok.pdf'),
        ]);
        await settle();
        flow().addFiles([file('ok.pdf')]);
        expect(st().sheets.map((s) => s.name), ['ok.pdf']);
        expect(st().notices.single, contains('already added'));
      },
    );

    test(
      'first previewable sheet becomes the preview; CAD never does',
      () async {
        await toSheetsStep();
        flow().addFiles([file('plan.dwg'), file('a.pdf'), file('b.png')]);
        await settle();
        final byName = {for (final s in st().sheets) s.name: s};
        expect(byName['plan.dwg']!.isPreview, isFalse);
        expect(byName['a.pdf']!.isPreview, isTrue);
        expect(byName['b.png']!.isPreview, isFalse);

        await flow().togglePreview(byName['plan.dwg']!.localId);
        expect(st().notices.single, contains('CAD'));
      },
    );

    test('at most two previews can be selected', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf'), file('b.pdf'), file('c.pdf')]);
      await settle();
      final ids = st().sheets.map((s) => s.localId).toList();
      await flow().togglePreview(ids[1]);
      expect(st().previewCount, 2);
      await flow().togglePreview(ids[2]);
      expect(st().previewCount, 2);
      expect(st().notices.single, contains('at most 2'));
    });

    test('picker results are queued', () async {
      await toSheetsStep();
      picker.next = [file('a.pdf')];
      await flow().pickSheets();
      await settle();
      expect(st().sheets.single.isDone, isTrue);
    });
  });

  group('upload state machine', () {
    test('queued → uploading (progress) → registering → done', () async {
      await toSheetsStep();
      uploader.hold = Completer<void>();
      flow().addFiles([file('a.pdf', size: 1000)]);
      await settle();

      var item = st().sheets.single;
      expect(item.status, SheetUploadStatus.uploading);
      expect(item.progress, closeTo(0.5, 0.001));

      uploader.hold!.complete();
      await settle();
      item = st().sheets.single;
      expect(item.status, SheetUploadStatus.done);
      expect(item.progress, 1);
      expect(item.serverSheetId, isNotNull);
      expect(
        repo.calls,
        containsAllInOrder(['requestSheetUpload', 'registerSheet']),
      );
      expect(uploader.headersSeen.single['Content-Type'], 'application/pdf');
      expect(repo.sheets['d1']!.single.isPreview, isTrue);
    });

    test('upload failure is surfaced and retry succeeds', () async {
      await toSheetsStep();
      uploader.failures.add(apiError(ApiErrorCodes.network, 'connection lost'));
      flow().addFiles([file('a.pdf')]);
      await settle();
      var item = st().sheets.single;
      expect(item.status, SheetUploadStatus.failed);
      expect(item.error, 'connection lost');
      expect(st().sheetsError, contains('failed'));

      flow().retrySheet(item.localId);
      await settle();
      item = st().sheets.single;
      expect(item.isDone, isTrue);
      expect(item.error, isNull);
      expect(repo.count('requestSheetUpload'), 2);
    });

    test(
      'registration failure retries without re-uploading the file',
      () async {
        await toSheetsStep();
        repo.failNext(
          'registerSheet',
          apiError(ApiErrorCodes.uploadInvalid, 'bad magic bytes'),
        );
        flow().addFiles([file('a.pdf')]);
        await settle();
        var item = st().sheets.single;
        expect(item.isFailed, isTrue);
        expect(item.objectKey, 'key/a.pdf');
        expect(uploader.uploaded, ['a.pdf']);

        flow().retrySheet(item.localId);
        await settle();
        item = st().sheets.single;
        expect(item.isDone, isTrue);
        expect(uploader.uploaded, ['a.pdf']); // not uploaded twice
        expect(repo.count('requestSheetUpload'), 1);
      },
    );

    test('files upload one after another', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf'), file('b.png'), file('c.jpg')]);
      await settle();
      expect(uploader.uploaded, ['a.pdf', 'b.png', 'c.jpg']);
      expect(st().sheets.every((s) => s.isDone), isTrue);
    });

    test('removing an uploaded sheet deletes it on the server', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf')]);
      await settle();
      await flow().removeSheet(st().sheets.single.localId);
      expect(st().sheets, isEmpty);
      expect(repo.sheets['d1'], isEmpty);
    });

    test('a failed server delete restores the sheet', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf')]);
      await settle();
      repo.failNext('deleteSheet', apiError(ApiErrorCodes.network, 'offline'));
      await flow().removeSheet(st().sheets.single.localId);
      expect(st().sheets, hasLength(1));
      expect(st().error, contains('offline'));
    });

    test('removing a sheet mid-upload cancels it', () async {
      await toSheetsStep();
      uploader.hold = Completer<void>();
      flow().addFiles([file('a.pdf')]);
      await settle();
      final id = st().sheets.single.localId;
      await flow().removeSheet(id);
      uploader.hold!.complete();
      await settle();
      expect(st().sheets, isEmpty);
      expect(repo.count('registerSheet'), 0);
    });

    test(
      'changing type or preview syncs; a server rejection rolls back',
      () async {
        await toSheetsStep();
        flow().addFiles([file('a.pdf'), file('b.pdf')]);
        await settle();
        final b = st().sheets[1];
        await flow().setSheetType(b.localId, SheetType.structural);
        expect(repo.sheets['d1']![1].type, SheetType.structural);

        repo.failNext(
          'updateSheet',
          apiError(ApiErrorCodes.validation, 'nope'),
        );
        await flow().togglePreview(b.localId);
        expect(st().sheets[1].isPreview, isFalse);
        expect(st().error, contains('nope'));
      },
    );
  });

  group('step guards', () {
    test('sheets step needs completed uploads and 1–2 previews', () async {
      await toSheetsStep();
      await flow().next();
      expect(st().step, UploadStep.sheets);
      expect(st().sheetsError, 'Add at least one sheet');

      flow().addFiles([file('plan.dwg')]);
      await settle();
      expect(st().sheetsError, contains('previews'));
      await flow().next();
      expect(st().step, UploadStep.sheets);

      flow().addFiles([file('a.pdf')]);
      await settle();
      expect(st().sheets[1].isPreview, isTrue); // auto-selected
      expect(st().sheetsError, isNull);
      await flow().next();
      expect(st().step, UploadStep.pricing);
    });

    test('paid drawings need a price before continuing', () async {
      await toSheetsStep(isFree: false);
      flow().addFiles([file('a.pdf')]);
      await settle();
      await flow().next();
      flow().updateForm((f) => f.copyWith(pricePaise: 0));
      await flow().next();
      expect(st().step, UploadStep.pricing);
      expect(st().pricingErrors['price'], isNotNull);

      flow().updateForm((f) => f.copyWith(pricePaise: 25000));
      await flow().next();
      expect(st().step, UploadStep.review);
      expect(repo.drawings['d1']!.pricePaise, 25000);
    });

    test('cannot jump ahead past an invalid step', () async {
      await flow().ensureLoaded();
      flow().goToStep(UploadStep.review);
      expect(st().step, UploadStep.details);
      expect(st().showErrors, isTrue);
    });
  });

  group('publish & processing', () {
    Future<void> toReview() async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf')]);
      await settle();
      await flow().next();
      await flow().next();
      expect(st().step, UploadStep.review);
    }

    test('publish is blocked while something is incomplete', () async {
      await toSheetsStep();
      await flow().publish();
      expect(st().publishBlockers, isNotEmpty);
      expect(repo.count('publish'), 0);
      expect(st().showErrors, isTrue);
    });

    test(
      'publishes, polls until PUBLISHED and clears the local draft',
      () async {
        await toReview();
        repo.pollStatuses.addAll([
          DrawingStatus.processing,
          DrawingStatus.processing,
          DrawingStatus.published,
        ]);
        await flow().publish();
        await settle();
        expect(st().phase, PublishPhase.published);
        expect(repo.count('publish'), 1);
        expect(store.stored, isNull);
      },
    );

    test('UNDER_REVIEW ends polling as its own outcome', () async {
      await toReview();
      repo.pollStatuses.add(DrawingStatus.underReview);
      await flow().publish();
      await settle();
      expect(st().phase, PublishPhase.underReview);
    });

    test('processing failure exposes the reason and can be retried', () async {
      await toReview();
      repo.failureReason = 'Could not render PDF';
      repo.pollStatuses.add(DrawingStatus.failed);
      await flow().publish();
      await settle();
      expect(st().phase, PublishPhase.failed);
      expect(st().failureReason, 'Could not render PDF');

      repo.pollStatuses.add(DrawingStatus.published);
      await flow().retryPublish();
      await settle();
      expect(st().phase, PublishPhase.published);
      expect(repo.count('publish'), 2);
    });

    test('editAfterFailure unlocks the form', () async {
      await toReview();
      repo.pollStatuses.add(DrawingStatus.failed);
      await flow().publish();
      await settle();
      flow().editAfterFailure();
      expect(st().phase, PublishPhase.idle);
      expect(st().step, UploadStep.details);
      expect(st().locked, isFalse);
    });

    test('server rejecting publish returns to idle with the message', () async {
      await toReview();
      repo.failNext(
        'publish',
        apiError(ApiErrorCodes.validation, 'Need 1-2 previews'),
      );
      await flow().publish();
      expect(st().phase, PublishPhase.idle);
      expect(st().error, 'Need 1-2 previews');
    });

    test('polling stalls after repeated errors and can be resumed', () async {
      await toReview();
      await flow().publish();
      await settle();
      // publish() already polled once with an empty status queue → still processing,
      // so inject errors for a fresh run.
      repo.failNext(
        'getDrawing',
        apiError(ApiErrorCodes.network, 'offline'),
        times: UploadFlow.maxConsecutivePollErrors,
      );
      repo.pollStatuses.add(DrawingStatus.published);
      await flow().resumePolling();
      expect(st().pollStalled, isTrue);
      expect(st().phase, PublishPhase.processing);

      await flow().resumePolling();
      expect(st().phase, PublishPhase.published);
      expect(st().pollStalled, isFalse);
    });

    test('form is locked while processing', () async {
      await toReview();
      repo.pollStatuses.add(DrawingStatus.processing);
      await flow().publish();
      flow().updateForm((f) => f.copyWith(title: 'changed title here'));
      expect(st().form.title, isNot('changed title here'));
    });
  });

  group('resume-safe drafts', () {
    test('restores a local snapshot without a server draft', () async {
      store.stored = StoredDraft(
        form: validForm().copyWith(title: 'Unsaved but typed'),
        stepIndex: 0,
      );
      await flow().ensureLoaded();
      expect(st().form.title, 'Unsaved but typed');
      expect(st().draftId, isNull);
    });

    test('restores the server draft, its sheets and the local edits', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf')]);
      await settle();
      flow().updateForm((f) => f.copyWith(title: 'Edited after last sync'));
      final saved = store.stored!;
      expect(saved.draftId, 'd1');

      // New "app session": fresh container, same fake server + store.
      container.dispose();
      container = ProviderContainer(
        overrides: [
          uploadRepositoryProvider.overrideWithValue(repo),
          sheetUploaderProvider.overrideWithValue(uploader),
          sheetPickerProvider.overrideWithValue(picker),
          draftStoreProvider.overrideWithValue(store),
          uploadDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      container.listen(uploadFlowProvider, (_, __) {});
      await flow().ensureLoaded();

      expect(st().draftId, 'd1');
      expect(st().form.title, 'Edited after last sync');
      expect(st().step, UploadStep.sheets);
      expect(st().sheets.single.name, 'a.pdf');
      expect(st().sheets.single.isDone, isTrue);
      expect(st().sheets.single.isPreview, isTrue);
    });

    test('resumeDraftId loads that draft from the server', () async {
      final record = await repo.createDraft(validForm());
      await repo.registerSheet(
        record.id,
        type: SheetType.architectural,
        objectKey: 'k',
        isPreview: true,
        fileName: 'p.pdf',
        sizeBytes: 10,
      );
      await flow().ensureLoaded(resumeDraftId: record.id);
      expect(st().draftId, record.id);
      expect(st().form.title, 'Modern 30x40 duplex');
      expect(st().sheets, hasLength(1));
    });

    test(
      'a draft deleted on the server falls back to the local form',
      () async {
        store.stored = StoredDraft(
          draftId: 'gone',
          form: validForm().copyWith(title: 'Local copy of title'),
        );
        await flow().ensureLoaded();
        expect(st().draftId, isNull);
        expect(st().form.title, 'Local copy of title');
        expect(st().error, isNull);
      },
    );

    test(
      'a network error while restoring keeps the draft id and shows a banner',
      () async {
        store.stored = StoredDraft(draftId: 'd9', form: validForm());
        repo.failNext('getDrawing', apiError(ApiErrorCodes.network, 'offline'));
        await flow().ensureLoaded();
        expect(st().draftId, 'd9');
        expect(st().error, contains('offline'));
        expect(st().loaded, isTrue);
      },
    );

    test('a draft that is still processing resumes polling', () async {
      await toSheetsStep();
      flow().addFiles([file('a.pdf')]);
      await settle();
      await flow().next();
      await flow().next();
      repo.pollStatuses.add(DrawingStatus.processing);
      await flow().publish();
      expect(st().phase, PublishPhase.processing);

      // Simulate restart while the server is still processing.
      store.stored = StoredDraft(
        draftId: 'd1',
        form: validForm(),
        stepIndex: 3,
      );
      container.dispose();
      container = ProviderContainer(
        overrides: [
          uploadRepositoryProvider.overrideWithValue(repo),
          sheetUploaderProvider.overrideWithValue(uploader),
          draftStoreProvider.overrideWithValue(store),
          uploadDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      container.listen(uploadFlowProvider, (_, __) {});
      repo.pollStatuses
        ..clear()
        ..add(DrawingStatus.published);
      repo.drawings['d1'] = repo.drawings['d1']!.copyWith(
        status: DrawingStatus.processing,
      );
      await flow().ensureLoaded();
      await settle();
      expect(st().phase, PublishPhase.published);
    });

    test('startNew clears the stored draft', () async {
      await toSheetsStep();
      await flow().startNew();
      expect(store.stored, isNull);
      expect(st().draftId, isNull);
      expect(st().form, const DrawingForm());
      expect(st().categories, isNotEmpty);
    });
  });
}
