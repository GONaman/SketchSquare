import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/notifications/data/dio_notifications_repository.dart';
import 'package:sketch_square/features/notifications/data/notifications_providers.dart';
import 'package:sketch_square/features/notifications/domain/app_notification.dart';
import 'package:sketch_square/features/notifications/domain/push_service.dart';
import 'package:sketch_square/features/notifications/presentation/notifications_screen.dart';
import 'package:sketch_square/features/notifications/presentation/push_registrar.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/scripted_adapter.dart';

Future<void> _open(
  WidgetTester tester,
  FakeNotificationsRepository repo, {
  String path = AppRoutes.profile,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await pumpApp(
    tester,
    overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  group('screen', () {
    testWidgets('Profile tile shows the unread badge and opens the inbox', (
      tester,
    ) async {
      final repo = FakeNotificationsRepository(
        items: [
          makeNotification('a', title: 'Sale A'),
          makeNotification('b', title: 'Sale B'),
          makeNotification('c', title: 'Old', read: true),
        ],
      );
      await _open(tester, repo);
      expect(
        find.descendant(
          of: find.byKey(const Key('tile-notifications')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tile-notifications')));
      await tester.pumpAndSettle();
      expect(find.text('Sale A'), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-c')), findsNothing);
    });

    testWidgets('shows the empty state', (tester) async {
      await _open(
        tester,
        FakeNotificationsRepository(),
        path: AppRoutes.notifications,
      );
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.byKey(const Key('mark-all-read')), findsNothing);
    });

    testWidgets('shows an error with retry', (tester) async {
      final repo =
          FakeNotificationsRepository()
            ..listError = const ApiException(
              code: ApiErrorCodes.network,
              message: 'Unable to reach the server.',
            );
      await _open(tester, repo, path: AppRoutes.notifications);
      expect(find.text('Unable to reach the server.'), findsOneWidget);
      repo.listError = null;
      repo.items.add(makeNotification('a', title: 'Back online'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Back online'), findsOneWidget);
    });

    testWidgets('tapping marks read and decrements the badge', (tester) async {
      final repo = FakeNotificationsRepository(
        items: [
          makeNotification('a', type: NotificationType.verificationResult),
          makeNotification('b', type: NotificationType.verificationResult),
        ],
      );
      await _open(tester, repo);
      await tester.tap(find.byKey(const Key('tile-notifications')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notification-a')));
      await tester.pumpAndSettle();
      expect(repo.markedRead, [
        ['a'],
      ]);
      expect(find.byKey(const ValueKey('unread-a')), findsNothing);
      expect(find.byKey(const ValueKey('unread-b')), findsOneWidget);
    });

    testWidgets('rolls back when marking read fails', (tester) async {
      final repo = FakeNotificationsRepository(
          items: [
            makeNotification('a', type: NotificationType.verificationResult),
          ],
        )
        ..markError = const ApiException(
          code: ApiErrorCodes.network,
          message: 'Unable to reach the server.',
        );
      await _open(tester, repo, path: AppRoutes.notifications);
      await tester.tap(find.byKey(const ValueKey('notification-a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unread-a')), findsOneWidget);
      expect(find.text('Unable to reach the server.'), findsOneWidget);
    });

    testWidgets('mark all read clears every unread dot', (tester) async {
      final repo = FakeNotificationsRepository(
        items: [makeNotification('a'), makeNotification('b')],
      );
      await _open(tester, repo, path: AppRoutes.notifications);
      await tester.tap(find.byKey(const Key('mark-all-read')));
      await tester.pumpAndSettle();
      expect(repo.markedRead, [null]);
      expect(find.byKey(const ValueKey('unread-a')), findsNothing);
      expect(find.byKey(const Key('mark-all-read')), findsNothing);
    });

    testWidgets('pages in more notifications', (tester) async {
      final repo = FakeNotificationsRepository(
        pageSize: 2,
        items: [for (var i = 0; i < 3; i++) makeNotification('n$i')],
      );
      await _open(tester, repo, path: AppRoutes.notifications);
      expect(repo.cursors, [null, '2']);
      expect(find.byKey(const ValueKey('notification-n2')), findsOneWidget);
    });
  });

  test('routeForNotification maps types to destinations', () {
    String? route(NotificationType t) =>
        routeForNotification(makeNotification('x', type: t));
    expect(route(NotificationType.saleMade), AppRoutes.wallet);
    expect(route(NotificationType.withdrawalStatus), AppRoutes.walletPayouts);
    expect(route(NotificationType.newReview), AppRoutes.manageDrawings);
    expect(route(NotificationType.interestReceived), AppRoutes.manageDrawings);
    expect(route(NotificationType.verificationResult), isNull);
    expect(route(NotificationType.unknown), isNull);
  });

  group('Dio repositories', () {
    late ScriptedAdapter adapter;

    Dio dio(ResponseBody Function(RequestOptions o) handler) {
      adapter = ScriptedAdapter(handler);
      return createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
        httpClientAdapter: adapter,
      );
    }

    test('lists notifications with unreadCount and unknown types', () async {
      final repo = DioNotificationsRepository(
        dio(
          (_) => jsonResponse({
            'items': [
              {
                'id': 'n1',
                'type': 'SALE_MADE',
                'title': 'Sale',
                'body': 'Net',
                'data': {'drawingId': 'd1', 'purchaseId': 7},
                'readAt': null,
                'createdAt': '2026-02-01T12:00:00Z',
              },
              {
                'id': 'n2',
                'type': 'FUTURE_THING',
                'title': 'x',
                'body': 'y',
                'data': {},
                'readAt': '2026-02-02T12:00:00Z',
                'createdAt': '2026-02-01T12:00:00Z',
              },
            ],
            'nextCursor': 'c2',
            'unreadCount': 5,
          }),
        ),
      );
      final res = await repo.list(cursor: 'c1', limit: 10);
      expect(adapter.requests.single.queryParameters, {
        'limit': 10,
        'cursor': 'c1',
      });
      expect(res.unreadCount, 5);
      expect(res.page.nextCursor, 'c2');
      expect(res.page.items[0].type, NotificationType.saleMade);
      expect(res.page.items[0].data['purchaseId'], '7');
      expect(res.page.items[0].isRead, isFalse);
      expect(res.page.items[1].type, NotificationType.unknown);
      expect(res.page.items[1].isRead, isTrue);
    });

    test('markRead sends ids, or no ids for mark-all', () async {
      final repo = DioNotificationsRepository(
        dio((_) => jsonResponse(null, 204)),
      );
      await repo.markRead(ids: ['a', 'b']);
      await repo.markRead();
      expect(adapter.requests[0].path, '/me/notifications/read');
      expect(adapter.requests[0].data, {
        'ids': ['a', 'b'],
      });
      expect(adapter.requests[1].data, <String, dynamic>{});
    });

    test('registers and unregisters the device token', () async {
      final repo = DioDeviceTokensRepository(
        dio((_) => jsonResponse(null, 204)),
      );
      await repo.register('tok', platform: 'android');
      await repo.unregister('tok');
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /me/device-tokens',
        'DELETE /me/device-tokens',
      ]);
      expect(adapter.requests[0].data, {'token': 'tok', 'platform': 'android'});
      expect(adapter.requests[1].data, {'token': 'tok'});
    });

    test('maps errors to ApiException', () async {
      final repo = DioNotificationsRepository(
        dio((_) => errorResponse(401, 'UNAUTHORIZED', 'Sign in')),
      );
      await expectLater(repo.list(), throwsA(isA<ApiException>()));
    });
  });

  group('PushRegistrar', () {
    test('registers, follows token refresh, unregisters', () async {
      final tokens = FakeDeviceTokensRepository();
      final push = FakePushService(token: 't1');
      final registrar = PushRegistrar(push, tokens);

      await registrar.register();
      expect(tokens.registered, [('t1', 'android')]);

      push.rotate('t2');
      await Future<void>.delayed(Duration.zero);
      expect(tokens.registered.last, ('t2', 'android'));

      await registrar.unregister();
      expect(tokens.unregistered, ['t2']);
      push.rotate('t3');
      await Future<void>.delayed(Duration.zero);
      expect(tokens.registered.length, 2);
    });

    test('swallows backend failures', () async {
      final tokens =
          FakeDeviceTokensRepository()
            ..error = const ApiException(
              code: ApiErrorCodes.network,
              message: 'down',
            );
      final registrar = PushRegistrar(FakePushService(token: 't'), tokens);
      await registrar.register();
      await registrar.unregister();
      expect(registrar.registeredToken, isNull);
    });

    test('NoopPushService yields no token', () async {
      final push = const NoopPushService(platform: 'ios');
      expect(await push.getToken(), isNull);
      final tokens = FakeDeviceTokensRepository();
      await PushRegistrar(push, tokens).register();
      expect(tokens.registered, isEmpty);
    });

    testWidgets('registers on sign-in and unregisters on sign-out', (
      tester,
    ) async {
      final tokens = FakeDeviceTokensRepository();
      final container = await pumpApp(
        tester,
        overrides: [
          pushServiceProvider.overrideWithValue(FakePushService(token: 'dev1')),
          deviceTokensRepositoryProvider.overrideWithValue(tokens),
        ],
      );
      await tester.pumpAndSettle();
      expect(tokens.registered, [('dev1', 'android')]);

      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(tokens.unregistered, ['dev1']);
    });
  });
}
