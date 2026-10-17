import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/drawings/domain/drawing_detail.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/interest/data/dio_interest_repository.dart';
import 'package:sketch_square/features/interest/data/interest_providers.dart';
import 'package:sketch_square/features/interest/domain/interest_repository.dart';
import 'package:sketch_square/features/manage_drawings/data/manage_drawings_providers.dart';
import 'package:sketch_square/features/manage_drawings/domain/manage_drawings_repository.dart';
import 'package:sketch_square/features/manage_drawings/presentation/manage_drawings_routes.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/scripted_adapter.dart';
import '../drawings/fixtures.dart';
import '../manage_drawings/fakes.dart';

class FakeInterestRepository implements InterestRepository {
  FakeInterestRepository({List<InterestedUser>? users, this.pageSize = 20})
    : users = users ?? [];

  final List<InterestedUser> users;
  final int pageSize;
  final set = <String, bool>{};
  final listed = <String?>[];
  ApiException? setError;
  ApiException? listError;

  @override
  Future<void> setInterest(String drawingId, {required bool interested}) async {
    if (setError != null) throw setError!;
    set[drawingId] = interested;
  }

  @override
  Future<CursorPage<InterestedUser>> listInterested(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    listed.add(cursor);
    if (listError != null) throw listError!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, users.length);
    return CursorPage(
      items: users.sublist(start, end),
      nextCursor: end < users.length ? '$end' : null,
    );
  }
}

InterestedUser user(String id, String name, {String? city = 'Pune'}) =>
    InterestedUser(
      id: id,
      fullName: name,
      city: city,
      createdAt: DateTime.utc(2026, 2, 1, 12),
    );

Map<String, dynamic> _viewer({
  bool isOwner = false,
  bool isPurchased = false,
  bool isInterested = false,
}) => {
  'isOwner': isOwner,
  'isPurchased': isPurchased,
  'inCart': false,
  'canDownload': isPurchased,
  'freeDownloadsRemaining': null,
  'myReview': null,
  'isFavorite': false,
  'isInterested': isInterested,
};

void main() {
  group('detail button', () {
    Future<FakeInterestRepository> open(
      WidgetTester tester, {
      Map<String, dynamic>? viewer,
      bool isFree = false,
      FakeInterestRepository? interest,
    }) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = interest ?? FakeInterestRepository();
      final detail = DrawingDetail.fromJson(
        detailJson(
          viewer: viewer ?? _viewer(),
          isFree: isFree,
          pricePaise: isFree ? 0 : 49900,
        ),
      );
      final container = await pumpApp(
        tester,
        overrides: [
          ...discoveryFakes(drawings: FakeDrawingsRepository(detail: detail)),
          interestRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await precacheGalleryImage(tester);
      container.read(appRouterProvider).go('/home/drawing/d1');
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('toggles interest on a paid drawing', (tester) async {
      final repo = await open(tester);
      expect(find.byKey(const Key('interest-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('interest-button')));
      await tester.pumpAndSettle();
      expect(repo.set, {'d1': true});
      expect(find.textContaining("You've told the architect"), findsOneWidget);

      await tester.tap(find.byKey(const Key('interest-button')));
      await tester.pumpAndSettle();
      expect(repo.set, {'d1': false});
    });

    testWidgets('starts in the interested state from viewer.isInterested', (
      tester,
    ) async {
      await open(tester, viewer: _viewer(isInterested: true));
      expect(find.textContaining("You've told the architect"), findsOneWidget);
    });

    testWidgets('rolls back with a message when the call fails', (
      tester,
    ) async {
      final repo =
          FakeInterestRepository()
            ..setError = const ApiException(
              code: ApiErrorCodes.network,
              message: 'Unable to reach the server.',
            );
      await open(tester, interest: repo);
      await tester.tap(find.byKey(const Key('interest-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not ready to buy'), findsOneWidget);
      expect(find.text('Unable to reach the server.'), findsOneWidget);
    });

    testWidgets('is hidden for free, own and already purchased drawings', (
      tester,
    ) async {
      await open(tester, isFree: true);
      expect(find.byKey(const Key('interest-button')), findsNothing);
    });

    testWidgets('hidden for the owner', (tester) async {
      await open(tester, viewer: _viewer(isOwner: true));
      expect(find.byKey(const Key('interest-button')), findsNothing);
    });

    testWidgets('hidden once purchased', (tester) async {
      await open(tester, viewer: _viewer(isPurchased: true));
      expect(find.byKey(const Key('interest-button')), findsNothing);
    });
  });

  group('owner list in Manage Drawings', () {
    Future<FakeInterestRepository> pumpManage(
      WidgetTester tester,
      List<ManagedDrawing> items, {
      FakeInterestRepository? interest,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppTheme.useGoogleFonts = false;
      final repo = interest ?? FakeInterestRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.manageDrawings,
        routes: manageDrawingsRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            manageDrawingsRepositoryProvider.overrideWithValue(
              FakeManageDrawingsRepository(items),
            ),
            interestRepositoryProvider.overrideWithValue(repo),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('paid published drawings list who is interested', (
      tester,
    ) async {
      final repo = await pumpManage(
        tester,
        [managed('p1')],
        interest: FakeInterestRepository(
          users: [user('u7', 'Ravi Kumar'), user('u8', 'Meera', city: null)],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('action-interested-p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('interested-title')), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Pune · Feb 1, 2026'), findsOneWidget);
      expect(find.text('Meera'), findsOneWidget);
      expect(repo.listed, [null]);
    });

    testWidgets('empty and error states', (tester) async {
      final repo = await pumpManage(tester, [managed('p1')]);
      await tester.tap(find.byKey(const ValueKey('action-interested-p1')));
      await tester.pumpAndSettle();
      expect(find.text('No interest yet'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      repo.listError = const ApiException(
        code: ApiErrorCodes.forbidden,
        message: 'Not yours',
      );
      await tester.tap(find.byKey(const ValueKey('action-interested-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Not yours'), findsOneWidget);
    });

    testWidgets('pages in more people as the list scrolls', (tester) async {
      final repo = await pumpManage(
        tester,
        [managed('p1')],
        interest: FakeInterestRepository(
          users: [for (var i = 0; i < 25; i++) user('u$i', 'Person $i')],
          pageSize: 10,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('action-interested-p1')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Person 24'),
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(repo.listed, [null, '10', '20']);
    });

    testWidgets('free and unpublished drawings have no Interested action', (
      tester,
    ) async {
      await pumpManage(tester, [
        managed('f1', isFree: true, pricePaise: 0),
        managed('d1', status: DrawingStatus.draft),
      ]);
      expect(find.byKey(const ValueKey('action-interested-f1')), findsNothing);
      expect(find.byKey(const ValueKey('action-interested-d1')), findsNothing);
    });
  });

  group('DioInterestRepository', () {
    late ScriptedAdapter adapter;
    late DioInterestRepository repo;

    void respond(ResponseBody Function(RequestOptions o) handler) {
      adapter = ScriptedAdapter(handler);
      repo = DioInterestRepository(
        createDio(
          tokenStore: SecureTokenStore(InMemorySecureStorage()),
          baseUrl: 'http://test',
          httpClientAdapter: adapter,
        ),
      );
    }

    test('PUT and DELETE the interest', () async {
      respond((_) => jsonResponse(null, 204));
      await repo.setInterest('d1', interested: true);
      await repo.setInterest('d1', interested: false);
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'PUT /drawings/d1/interest',
        'DELETE /drawings/d1/interest',
      ]);
    });

    test('maps the 400 for free drawings', () async {
      respond((_) => errorResponse(400, 'VALIDATION_ERROR', 'Free drawing'));
      await expectLater(
        repo.setInterest('d1', interested: true),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Free drawing',
          ),
        ),
      );
    });

    test('lists interested users with the cursor', () async {
      respond(
        (_) => jsonResponse({
          'items': [
            {
              'user': {'id': 'u1', 'fullName': 'Ravi', 'city': null},
              'createdAt': '2026-02-01T10:00:00.000Z',
            },
          ],
          'nextCursor': 'n',
        }),
      );
      final page = await repo.listInterested('d1', cursor: 'c', limit: 5);
      final req = adapter.requests.single;
      expect(req.path, '/drawings/d1/interests');
      expect(req.queryParameters, {'limit': 5, 'cursor': 'c'});
      expect(page.nextCursor, 'n');
      expect(page.items.single.fullName, 'Ravi');
      expect(page.items.single.city, isNull);
    });
  });
}
