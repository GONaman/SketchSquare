import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/admin/data/dio_plagiarism_repository.dart';
import 'package:sketch_square/features/admin/domain/plagiarism_flag.dart';
import 'package:sketch_square/features/admin/presentation/plagiarism_providers.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';

import '../../helpers/auth_test_utils.dart';
import '../../helpers/fake_plagiarism.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/scripted_adapter.dart';

final _admin = stubUser.copyWith(role: UserRole.admin);

Future<void> _open(
  WidgetTester tester,
  FakePlagiarismRepository repo, {
  String path = '${AppRoutes.admin}/plagiarism',
}) async {
  useTallScreen(tester);
  final container = await pumpApp(
    tester,
    user: _admin,
    overrides: [plagiarismRepositoryProvider.overrideWithValue(repo)],
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  late FakePlagiarismRepository repo;

  setUp(() {
    repo = FakePlagiarismRepository(
      items: [
        makeFlag('f1'),
        makeFlag('f2', distance: 8),
        makeFlag(
          'f3',
          status: PlagiarismFlagStatus.rejected,
          reviewNote: 'Copied plan',
        ),
      ],
    );
  });

  testWidgets('is reachable from the admin home and lists pending pairs', (
    tester,
  ) async {
    await _open(tester, repo, path: AppRoutes.admin);
    await tester.tap(find.byKey(const Key('open-plagiarism')));
    await tester.pumpAndSettle();

    expect(inAppBar('Plagiarism review'), findsOneWidget);
    expect(find.text('Held f1'), findsOneWidget);
    expect(find.text('Original f1'), findsOneWidget);
    expect(find.text('Held f3'), findsNothing);
    expect(find.text('94% similar previews (hash distance 4)'), findsOneWidget);
    expect(find.text('Uploaded (held)'), findsNWidgets(2));
    expect(find.text('Existing'), findsNWidgets(2));
  });

  testWidgets('approve confirms, calls the API and refreshes the list', (
    tester,
  ) async {
    await _open(tester, repo);
    await tester.tap(find.byKey(const Key('approve-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve-confirm')));
    await tester.pumpAndSettle();

    expect(repo.approved, ['f1']);
    expect(find.text('Held f1'), findsNothing);
    expect(find.text('Held f2'), findsOneWidget);
    expect(find.text('Drawing approved and published.'), findsOneWidget);
  });

  testWidgets('cancelling the approve dialog does nothing', (tester) async {
    await _open(tester, repo);
    await tester.tap(find.byKey(const Key('approve-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve-cancel')));
    await tester.pumpAndSettle();
    expect(repo.approved, isEmpty);
    expect(find.text('Held f1'), findsOneWidget);
  });

  testWidgets('reject requires a reason and sends it', (tester) async {
    await _open(tester, repo);
    await tester.tap(find.byKey(const Key('reject-f1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reject-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a reason for the uploader.'), findsOneWidget);
    expect(repo.rejected, isEmpty);

    await tester.enterText(
      find.byKey(const Key('reject-reason-field')),
      '  Copied from another architect  ',
    );
    await tester.tap(find.byKey(const Key('reject-confirm')));
    await tester.pumpAndSettle();

    expect(repo.rejected, [('f1', 'Copied from another architect')]);
    expect(find.text('Held f1'), findsNothing);
  });

  testWidgets('a 409 shows the message and refreshes the stale list', (
    tester,
  ) async {
    await _open(tester, repo);
    repo.decisionError = const ApiException(
      code: ApiErrorCodes.conflict,
      message: 'Already decided',
      statusCode: 409,
    );
    await tester.tap(find.byKey(const Key('approve-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Already decided'), findsOneWidget);
    // Dashboard count, first load and the post-409 refresh.
    expect(repo.statusQueries.length, 3);
  });

  testWidgets('decided flags are read-only with the review note', (
    tester,
  ) async {
    await _open(tester, repo);
    await tester.tap(find.byKey(const Key('plagiarism-filter-REJECTED')));
    await tester.pumpAndSettle();

    expect(repo.statusQueries.last, PlagiarismFlagStatus.rejected);
    expect(find.text('Held f3'), findsOneWidget);
    expect(find.text('Rejected: Copied plan'), findsOneWidget);
    expect(find.byKey(const Key('approve-f3')), findsNothing);
  });

  testWidgets('empty queue and load errors have states', (tester) async {
    repo.items.clear();
    await _open(tester, repo);
    expect(find.text('Nothing to review'), findsOneWidget);

    repo.listError = const ApiException(
      code: ApiErrorCodes.network,
      message: 'Offline',
    );
    await tester.tap(find.byKey(const Key('plagiarism-filter-APPROVED')));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('non-admins cannot open the screen', (tester) async {
    useTallScreen(tester);
    final container = await pumpApp(
      tester,
      user: stubUser,
      overrides: [plagiarismRepositoryProvider.overrideWithValue(repo)],
    );
    container.read(appRouterProvider).go('${AppRoutes.admin}/plagiarism');
    await tester.pumpAndSettle();
    expect(find.text('Plagiarism review'), findsNothing);
  });

  group('DioPlagiarismRepository', () {
    late ScriptedAdapter adapter;
    late DioPlagiarismRepository dioRepo;

    void respond(ResponseBody Function(RequestOptions o) handler) {
      adapter = ScriptedAdapter((o) => handler(o));
      dioRepo = DioPlagiarismRepository(
        createDio(
          tokenStore: SecureTokenStore(InMemorySecureStorage()),
          baseUrl: 'http://test',
          httpClientAdapter: adapter,
        ),
      );
    }

    Map<String, dynamic> drawing(String id) => {
      'id': id,
      'title': 'Plan $id',
      'description': 'd',
      'city': 'Jaipur',
      'plotLengthFt': 40,
      'plotBreadthFt': 30.5,
      'pricePaise': 0,
      'isFree': true,
      'architect': {'id': 'a', 'fullName': 'Ann', 'city': 'Jaipur'},
      'sheets': [
        {'id': 's', 'previewUrl': 'http://cdn/$id.png', 'isPreview': true},
      ],
    };

    test('parses the contract item and sends status/cursor', () async {
      respond(
        (_) => jsonResponse({
          'items': [
            {
              'id': 'f1',
              'status': 'PENDING',
              'hammingDistance': 6,
              'reviewNote': null,
              'reviewedAt': null,
              'createdAt': '2026-02-01T10:00:00.000Z',
              'drawing': drawing('d1'),
              'matchedDrawing': drawing('d2'),
              'flaggedSheet': {'id': 's1', 'previewUrl': 'http://cdn/f.png'},
              'matchedSheet': {'id': 's2', 'previewUrl': null},
            },
          ],
          'nextCursor': 'n',
        }),
      );
      final page = await dioRepo.flags(cursor: 'c', limit: 10);
      expect(adapter.requests.single.path, '/admin/plagiarism-flags');
      expect(adapter.requests.single.queryParameters, {
        'status': 'PENDING',
        'limit': 10,
        'cursor': 'c',
      });
      expect(page.nextCursor, 'n');
      final f = page.items.single;
      expect(f.hammingDistance, 6);
      expect(f.drawing.architectName, 'Ann');
      expect(f.drawing.plotBreadthFt, 30.5);
      expect(f.flaggedPreviewUrl, 'http://cdn/f.png');
      // Falls back to the matched drawing's first preview sheet.
      expect(f.matchedPreviewUrl, 'http://cdn/d2.png');
    });

    test('approve and reject post to the flag', () async {
      respond((_) => jsonResponse({'ok': true}, 201));
      await dioRepo.approve('f1');
      await dioRepo.reject('f1', reason: 'copy');
      expect(adapter.requests[0].path, '/admin/plagiarism-flags/f1/approve');
      expect(adapter.requests[1].path, '/admin/plagiarism-flags/f1/reject');
      expect(adapter.requests[1].data, {'reason': 'copy'});
    });

    test('maps API errors', () async {
      respond((_) => errorResponse(409, 'CONFLICT', 'Already decided'));
      await expectLater(
        dioRepo.approve('f1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });
  });

  testWidgets('flag cards fit a small phone at 1.3x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final container = await pumpApp(
      tester,
      user: _admin,
      overrides: [plagiarismRepositoryProvider.overrideWithValue(repo)],
    );
    container.read(appRouterProvider).go('${AppRoutes.admin}/plagiarism');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flag-f1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
