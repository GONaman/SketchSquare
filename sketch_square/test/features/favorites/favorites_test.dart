import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/favorites/data/dio_favorites_repository.dart';
import 'package:sketch_square/features/favorites/data/favorites_providers.dart';
import 'package:sketch_square/features/favorites/domain/favorites_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/scripted_adapter.dart';
import '../drawings/fixtures.dart';

class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository(this.all, {this.pageSize = 20});

  final List<DrawingSummary> all;
  final int pageSize;
  final cursors = <String?>[];
  ApiException? error;

  @override
  Future<CursorPage<DrawingSummary>> list({
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    cursors.add(cursor);
    if (error != null) throw error!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, all.length);
    return CursorPage(
      items: all.sublist(start, end),
      nextCursor: end < all.length ? '$end' : null,
    );
  }
}

Future<void> _open(
  WidgetTester tester,
  FakeFavoritesRepository repo, {
  FakeDrawingActions? actions,
  String path = AppRoutes.favorites,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await pumpApp(
    tester,
    overrides: [
      ...discoveryFakes(actions: actions),
      favoritesRepositoryProvider.overrideWithValue(repo),
    ],
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Profile has a Favorites tile that opens the list', (
    tester,
  ) async {
    final repo = FakeFavoritesRepository([summary('a', title: 'Alpha')]);
    await _open(tester, repo, path: AppRoutes.profile);
    await tester.tap(find.byKey(const Key('tile-favorites')));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('lists favorites, empty state otherwise', (tester) async {
    await _open(
      tester,
      FakeFavoritesRepository([
        summary('a', title: 'Alpha'),
        summary('b', title: 'Beta'),
      ]),
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byKey(const Key('favorite-toggle')), findsNWidgets(2));
  });

  testWidgets('empty list shows guidance', (tester) async {
    await _open(tester, FakeFavoritesRepository([]));
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('a load failure offers retry', (tester) async {
    final repo = FakeFavoritesRepository([summary('a', title: 'Alpha')])
      ..error = const ApiException(
        code: ApiErrorCodes.network,
        message: 'Offline',
      );
    await _open(tester, repo);
    expect(find.text('Offline'), findsOneWidget);
    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('tapping the heart removes the tile through the repository', (
    tester,
  ) async {
    final actions = FakeDrawingActions();
    await _open(
      tester,
      FakeFavoritesRepository([
        summary('a', title: 'Alpha'),
        summary('b', title: 'Beta'),
      ]),
      actions: actions,
    );
    await tester.tap(find.byKey(const Key('favorite-toggle')).first);
    await tester.pumpAndSettle();

    expect(actions.favorites, {'a': false});
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Removed from favorites'), findsOneWidget);
  });

  testWidgets('a failed removal rolls the tile back and shows the error', (
    tester,
  ) async {
    final actions =
        FakeDrawingActions()
          ..error = const ApiException(
            code: ApiErrorCodes.network,
            message: 'Unable to reach the server.',
          );
    await _open(
      tester,
      FakeFavoritesRepository([
        summary('a', title: 'Alpha'),
        summary('b', title: 'Beta'),
      ]),
      actions: actions,
    );
    await tester.tap(find.byKey(const Key('favorite-toggle')).first);
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Unable to reach the server.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alpha')).dx,
      lessThan(tester.getTopLeft(find.text('Beta')).dx),
    );
  });

  testWidgets('opens the drawing detail inside the profile stack', (
    tester,
  ) async {
    await _open(
      tester,
      FakeFavoritesRepository([summary('d1', title: 'Alpha')]),
    );
    await precacheGalleryImage(tester);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorite-button')), findsOneWidget);
  });

  testWidgets('loads the next page near the end', (tester) async {
    final repo = FakeFavoritesRepository([
      for (var i = 0; i < 30; i++) summary('d$i', title: 'Plan $i'),
    ], pageSize: 12);
    await _open(tester, repo);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(repo.cursors.first, isNull);
    expect(repo.cursors[1], '12');
    expect(find.text('Plan 29'), findsOneWidget);
  });

  group('DioFavoritesRepository', () {
    test('GETs /me/favorites with the cursor and parses summaries', () async {
      final adapter = ScriptedAdapter(
        (_) => jsonResponse({
          'items': [summaryJson(id: 'x', title: 'Hearted')],
          'nextCursor': 'n2',
        }),
      );
      final repo = DioFavoritesRepository(
        createDio(
          tokenStore: SecureTokenStore(InMemorySecureStorage()),
          baseUrl: 'http://test',
          httpClientAdapter: adapter,
        ),
      );
      final page = await repo.list(cursor: 'c1', limit: 10);
      final req = adapter.requests.single;
      expect(req.path, '/me/favorites');
      expect(req.queryParameters, {'limit': 10, 'cursor': 'c1'});
      expect(page.nextCursor, 'n2');
      expect(page.items.single.title, 'Hearted');
    });
  });
}
