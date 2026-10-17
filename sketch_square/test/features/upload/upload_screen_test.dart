import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/upload/data/upload_providers.dart';
import 'package:sketch_square/features/upload/domain/contribution_status.dart';
import 'package:sketch_square/features/upload/domain/draft_store.dart';
import 'package:sketch_square/features/upload/presentation/upload_screen.dart';

import 'fakes.dart';

void main() {
  late FakeUploadRepository repo;
  late FakeSheetUploader uploader;
  late FakeSheetPicker picker;
  late InMemoryDraftStore store;

  setUp(() {
    AppTheme.useGoogleFonts = false;
    repo = FakeUploadRepository();
    uploader = FakeSheetUploader();
    picker = FakeSheetPicker();
    store = InMemoryDraftStore();
  });

  Future<void> pumpUpload(WidgetTester tester, {String? draftId}) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uploadRepositoryProvider.overrideWithValue(repo),
          sheetUploaderProvider.overrideWithValue(uploader),
          sheetPickerProvider.overrideWithValue(picker),
          draftStoreProvider.overrideWithValue(store),
          uploadDelayProvider.overrideWithValue((_) async {}),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: UploadScreen(draftId: draftId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  group('details step', () {
    testWidgets('empty form shows validation errors and stays put', (
      tester,
    ) async {
      await pumpUpload(tester);
      await tapKey(tester, 'continue');
      expect(find.text('Enter a title'), findsOneWidget);
      expect(find.text('Enter a description'), findsOneWidget);
      expect(find.text('Choose a category'), findsOneWidget);
      expect(find.text('Enter a city'), findsOneWidget);
      expect(find.byKey(const ValueKey('field-title')), findsOneWidget);
      expect(repo.count('createDraft'), 0);
    });

    testWidgets('typing is validated and a valid form continues', (
      tester,
    ) async {
      await pumpUpload(tester);
      await tester.enterText(find.byKey(const ValueKey('field-title')), 'Hi');
      await tapKey(tester, 'continue');
      expect(find.text('Title must be at least 5 characters'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('field-title')),
        'Modern 30x40 duplex',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-description')),
        'A two floor duplex with a central courtyard.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-city')),
        'Bengaluru',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-plot-length')),
        '40',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-plot-breadth')),
        '30',
      );
      await tester.enterText(find.byKey(const ValueKey('field-floors')), '2');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Houses').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('plot-area')), findsOneWidget);
      expect(find.text('≈ 1200 sq ft'), findsOneWidget);

      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('pick-sheets')), findsOneWidget);
      expect(repo.count('createDraft'), 1);
    });

    testWidgets('switching to metres updates the area estimate', (
      tester,
    ) async {
      store.stored = StoredDraft(form: validForm());
      await pumpUpload(tester);
      expect(find.text('≈ 1200 sq ft'), findsOneWidget);
      await tester.tap(find.text('m'));
      await tester.pumpAndSettle();
      // 40 m × 30 m ≈ 12,917 sq ft
      expect(find.text('≈ 12917 sq ft'), findsOneWidget);
    });

    testWidgets('tags can be added, deduplicated and removed', (tester) async {
      await pumpUpload(tester);
      await tester.enterText(find.byKey(const ValueKey('field-tag')), 'vastu');
      await tapKey(tester, 'add-tag');
      expect(find.widgetWithText(InputChip, 'vastu'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('field-tag')), 'Vastu');
      await tapKey(tester, 'add-tag');
      expect(find.text('Tag already added'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'vastu'), findsNothing);
    });

    testWidgets('save draft stores locally when the form is incomplete', (
      tester,
    ) async {
      await pumpUpload(tester);
      await tester.enterText(
        find.byKey(const ValueKey('field-title')),
        'Half done title',
      );
      await tapKey(tester, 'save-draft');
      expect(find.textContaining('Saved on this device'), findsOneWidget);
      expect(repo.count('createDraft'), 0);
      expect(store.stored?.form.title, 'Half done title');
    });

    testWidgets('a failing save shows a banner and can be retried', (
      tester,
    ) async {
      store.stored = StoredDraft(form: validForm());
      repo.failNext('createDraft', apiError('NETWORK_ERROR', 'offline'));
      await pumpUpload(tester);
      await tapKey(tester, 'continue');
      expect(find.textContaining("Couldn't save your draft"), findsOneWidget);
      expect(find.byKey(const ValueKey('field-title')), findsOneWidget);
      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('pick-sheets')), findsOneWidget);
    });
  });

  group('sheets step', () {
    Future<void> openSheets(WidgetTester tester) async {
      store.stored = StoredDraft(form: validForm());
      await pumpUpload(tester);
      await tapKey(tester, 'continue');
    }

    testWidgets('shows progress while uploading, then done', (tester) async {
      await openSheets(tester);
      uploader.hold = Completer<void>();
      picker.next = [file('plan.pdf', size: 1000)];
      await tapKey(tester, 'pick-sheets');

      expect(find.text('1000 B · Uploading 50%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('sheet-progress-plan.pdf')),
      );
      expect(bar.value, closeTo(0.5, 0.001));

      uploader.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('1000 B · Uploaded'), findsOneWidget);
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('sheet-preview-plan.pdf')),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('a failed upload can be retried', (tester) async {
      await openSheets(tester);
      uploader.failures.add(apiError('NETWORK_ERROR', 'connection lost'));
      picker.next = [file('plan.pdf')];
      await tapKey(tester, 'pick-sheets');
      expect(find.textContaining('connection lost'), findsOneWidget);

      await tapKey(tester, 'retry-sheet-plan.pdf');
      expect(find.textContaining('Uploaded'), findsOneWidget);
    });

    testWidgets('rejected files are explained', (tester) async {
      await openSheets(tester);
      picker.next = [file('notes.txt')];
      await tapKey(tester, 'pick-sheets');
      expect(find.textContaining('Unsupported file type'), findsOneWidget);
    });

    testWidgets('CAD sheets cannot be previews; continue needs a preview', (
      tester,
    ) async {
      await openSheets(tester);
      picker.next = [file('plan.dwg')];
      await tapKey(tester, 'pick-sheets');
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('sheet-preview-plan.dwg')),
            )
            .onChanged,
        isNull,
      );
      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('sheets-error')), findsOneWidget);
      expect(find.text('Mark 1–2 sheets as previews'), findsOneWidget);
    });

    testWidgets('removing a sheet deletes it', (tester) async {
      await openSheets(tester);
      picker.next = [file('plan.pdf')];
      await tapKey(tester, 'pick-sheets');
      await tapKey(tester, 'remove-sheet-plan.pdf');
      expect(find.text('No sheets yet'), findsOneWidget);
    });
  });

  group('pricing, review and publish', () {
    Future<void> toPricing(WidgetTester tester, {bool free = false}) async {
      store.stored = StoredDraft(form: validForm(isFree: free));
      await pumpUpload(tester);
      await tapKey(tester, 'continue');
      picker.next = [file('plan.pdf')];
      await tapKey(tester, 'pick-sheets');
      await tapKey(tester, 'continue');
    }

    testWidgets('shows the seller net after the platform fee', (tester) async {
      await toPricing(tester);
      expect(find.byKey(const ValueKey('field-price')), findsOneWidget);
      expect(find.textContaining('₹449.10'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('field-price')), '1000');
      await tester.pumpAndSettle();
      expect(find.textContaining('₹900'), findsOneWidget);
    });

    testWidgets('paid drawing needs a price', (tester) async {
      await toPricing(tester);
      await tester.enterText(find.byKey(const ValueKey('field-price')), '');
      await tapKey(tester, 'continue');
      expect(find.textContaining('Enter a price of at least'), findsOneWidget);
    });

    testWidgets('free drawings hide the price field', (tester) async {
      await toPricing(tester, free: true);
      expect(find.byKey(const ValueKey('field-price')), findsNothing);
      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('review-price')), findsOneWidget);
      expect(find.text('Free'), findsWidgets);
    });

    testWidgets('publishes and lands on the live state', (tester) async {
      await toPricing(tester, free: true);
      await tapKey(tester, 'continue');
      repo.pollStatuses.addAll([
        DrawingStatus.processing,
        DrawingStatus.published,
      ]);
      await tapKey(tester, 'publish');
      expect(find.text('Your drawing is live'), findsOneWidget);
      expect(store.stored, isNull);

      await tapKey(tester, 'start-new');
      expect(find.byKey(const ValueKey('field-title')), findsOneWidget);
    });

    testWidgets('processing failure shows the reason and can be retried', (
      tester,
    ) async {
      await toPricing(tester, free: true);
      await tapKey(tester, 'continue');
      repo.failureReason = 'Could not render PDF';
      repo.pollStatuses.add(DrawingStatus.failed);
      await tapKey(tester, 'publish');
      expect(find.text('Could not render PDF'), findsOneWidget);

      repo.pollStatuses.add(DrawingStatus.underReview);
      await tapKey(tester, 'retry-publish');
      expect(find.text('Under review by admins'), findsOneWidget);
    });

    testWidgets('shows the contribution rule and keeps Paid when allowed', (
      tester,
    ) async {
      repo.contribution = const ContributionStatus(
        guidance: 'Your first paid drawing is always allowed.',
      );
      await toPricing(tester);
      expect(find.byKey(const ValueKey('contribution-banner')), findsOneWidget);
      expect(find.textContaining('first paid drawing'), findsOneWidget);
      expect(find.byKey(const ValueKey('contribution-blocked')), findsNothing);
      expect(find.byKey(const ValueKey('field-price')), findsOneWidget);
    });

    testWidgets('disables Paid and blocks continue when contribution is due', (
      tester,
    ) async {
      repo.contribution = const ContributionStatus(
        paidPublished: 1,
        freeNeeded: 1,
        canPublishPaid: false,
        guidance: 'Publish one free drawing before your next paid one.',
      );
      await toPricing(tester);
      expect(find.textContaining('Publish one free drawing'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('contribution-blocked')),
        findsOneWidget,
      );
      expect(find.textContaining('make this one free'), findsOneWidget);

      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('review-price')), findsNothing);

      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('contribution-blocked')), findsNothing);
      await tapKey(tester, 'continue');
      expect(find.byKey(const ValueKey('review-price')), findsOneWidget);
    });

    testWidgets('CONTRIBUTION_REQUIRED on publish shows a friendly message', (
      tester,
    ) async {
      await toPricing(tester);
      await tapKey(tester, 'continue');
      repo.failNext(
        'publish',
        const ApiException(
          code: ApiErrorCodes.contributionRequired,
          message: 'raw server text',
          statusCode: 403,
          details: {'freeNeeded': 2},
        ),
      );
      await tapKey(tester, 'publish');
      expect(
        find.textContaining('2 more published free drawings'),
        findsOneWidget,
      );
      expect(find.text('raw server text'), findsNothing);
      expect(repo.count('fetchContributionStatus'), greaterThan(1));
    });

    testWidgets('a stalled poll offers a manual re-check', (tester) async {
      await toPricing(tester, free: true);
      await tapKey(tester, 'continue');
      repo.failNext(
        'getDrawing',
        apiError('NETWORK_ERROR', 'offline'),
        times: 5,
      );
      await tapKey(tester, 'publish');
      expect(find.text('Still processing…'), findsOneWidget);

      repo.pollStatuses.add(DrawingStatus.published);
      await tapKey(tester, 'check-again');
      expect(find.text('Your drawing is live'), findsOneWidget);
    });
  });

  testWidgets('resumes a server draft by id', (tester) async {
    final record = await repo.createDraft(validForm());
    await pumpUpload(tester, draftId: record.id);
    final title = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('field-title')),
        matching: find.byType(TextField),
      ),
    );
    expect(title.controller!.text, 'Modern 30x40 duplex');
  });
}
