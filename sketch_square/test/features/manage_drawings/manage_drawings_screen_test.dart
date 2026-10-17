import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/manage_drawings/data/manage_drawings_providers.dart';
import 'package:sketch_square/features/manage_drawings/domain/manage_drawings_repository.dart';
import 'package:sketch_square/features/manage_drawings/presentation/manage_drawings_routes.dart';

import 'fakes.dart';

void main() {
  late FakeManageDrawingsRepository repo;
  late GoRouter router;

  setUp(() => AppTheme.useGoogleFonts = false);

  Future<void> pumpManage(
    WidgetTester tester,
    List<ManagedDrawing> items, {
    int pageSize = 20,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repo = FakeManageDrawingsRepository(items, pageSize: pageSize);
    router = GoRouter(
      initialLocation: AppRoutes.manageDrawings,
      routes: [
        ...manageDrawingsRoutes,
        GoRoute(
          path: AppRoutes.upload,
          builder:
              (_, state) => Scaffold(
                body: Text('UPLOAD ${state.uri.queryParameters['draft']}'),
              ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manageDrawingsRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('lists drawings with status, price and per-drawing stats', (
    tester,
  ) async {
    await pumpManage(tester, [
      managed('pub'),
      managed('free', isFree: true),
      managed('dr', status: DrawingStatus.draft),
      managed('fail', status: DrawingStatus.failed),
    ]);
    expect(find.text('Manage drawings'), findsOneWidget);
    expect(find.text('Drawing pub'), findsOneWidget);
    expect(find.text('Published'), findsWidgets);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Rejected'), findsWidgets); // chip + status badge
    expect(find.text('₹499'), findsWidgets);
    expect(find.text('Free'), findsWidgets);

    final stats = find.byKey(const ValueKey('stats-pub'));
    expect(
      find.descendant(of: stats, matching: find.text('120 views')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: stats, matching: find.text('3 sales')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: stats, matching: find.text('4.5 (2)')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('stats-dr')), findsNothing);
  });

  testWidgets('status filter reloads with the chosen status', (tester) async {
    await pumpManage(tester, [
      managed('pub'),
      managed('dr', status: DrawingStatus.draft),
    ]);
    await tapKey(tester, 'filter-drafts');
    expect(repo.listFilters.last, DrawingStatus.draft);
    expect(find.text('Drawing dr'), findsOneWidget);
    expect(find.text('Drawing pub'), findsNothing);

    await tapKey(tester, 'filter-processing');
    expect(find.text('Nothing in processing'), findsOneWidget);
  });

  testWidgets('empty list invites the seller to upload', (tester) async {
    await pumpManage(tester, []);
    expect(find.text('No drawings yet'), findsOneWidget);
    await tapKey(tester, 'empty-upload');
    expect(find.text('UPLOAD null'), findsOneWidget);
  });

  testWidgets('first page error can be retried', (tester) async {
    repo = FakeManageDrawingsRepository([managed('a')]);
    repo.failNext('list', apiError('NETWORK_ERROR', 'offline'));
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: AppRoutes.manageDrawings,
      routes: manageDrawingsRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manageDrawingsRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('offline'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Drawing a'), findsOneWidget);
  });

  testWidgets('continue editing a draft opens the upload flow on that draft', (
    tester,
  ) async {
    await pumpManage(tester, [managed('dr', status: DrawingStatus.draft)]);
    await tapKey(tester, 'action-continueEditing-dr');
    expect(find.text('UPLOAD dr'), findsOneWidget);
  });

  testWidgets('rejected drawings offer fix & retry and delete', (tester) async {
    await pumpManage(tester, [managed('f', status: DrawingStatus.failed)]);
    expect(find.text('Fix & retry'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.textContaining('Processing failed'), findsOneWidget);
  });

  testWidgets('processing drawings can only be followed', (tester) async {
    await pumpManage(tester, [
      managed('p', status: DrawingStatus.processing),
    ], settle: false);
    expect(find.text('View progress'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('removing needs confirmation, then drops the card', (
    tester,
  ) async {
    await pumpManage(tester, [managed('a'), managed('b')]);
    await tapKey(tester, 'action-remove-a');
    expect(find.textContaining('keep their access'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.count('delete'), 0);

    await tapKey(tester, 'action-remove-a');
    await tapKey(tester, 'confirm-remove');
    expect(repo.count('delete'), 1);
    expect(find.text('Drawing a'), findsNothing);
    expect(find.text('Drawing b'), findsOneWidget);
  });

  testWidgets('a failed delete keeps the card and shows the error', (
    tester,
  ) async {
    await pumpManage(tester, [managed('d', status: DrawingStatus.draft)]);
    repo.failNext('delete', apiError('NETWORK_ERROR', 'offline'));
    await tapKey(tester, 'action-delete-d');
    expect(find.textContaining('permanently deletes'), findsOneWidget);
    await tapKey(tester, 'confirm-remove');
    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Drawing d'), findsOneWidget);
  });

  group('editing a published drawing', () {
    testWidgets('saves title, description and price', (tester) async {
      await pumpManage(tester, [managed('a')]);
      await tapKey(tester, 'action-edit-a');
      expect(find.byKey(const ValueKey('edit-title')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('edit-title')),
        'Renamed villa plan',
      );
      await tester.enterText(find.byKey(const ValueKey('edit-price')), '599');
      await tester.pumpAndSettle();
      expect(find.textContaining('₹539.10'), findsOneWidget); // 10% fee
      await tapKey(tester, 'edit-save');

      expect(repo.updates.single['title'], 'Renamed villa plan');
      expect(repo.updates.single['pricePaise'], 59900);
      expect(find.text('Renamed villa plan'), findsOneWidget);
      expect(find.text('₹599'), findsOneWidget);
      expect(find.text('Changes saved'), findsOneWidget);
    });

    testWidgets('validates before saving', (tester) async {
      await pumpManage(tester, [managed('a')]);
      await tapKey(tester, 'action-edit-a');
      await tester.enterText(find.byKey(const ValueKey('edit-title')), 'abc');
      await tapKey(tester, 'edit-save');
      expect(find.text('Title must be at least 5 characters'), findsOneWidget);
      expect(repo.count('updatePublished'), 0);
    });

    testWidgets('free drawings cannot change price', (tester) async {
      await pumpManage(tester, [managed('a', isFree: true, pricePaise: 0)]);
      await tapKey(tester, 'action-edit-a');
      expect(find.byKey(const ValueKey('edit-price')), findsNothing);
      expect(find.textContaining('price cannot be changed'), findsOneWidget);
    });

    testWidgets('a rejected save keeps the sheet open with the message', (
      tester,
    ) async {
      await pumpManage(tester, [managed('a')]);
      repo.failNext('updatePublished', apiError('VALIDATION_ERROR', 'Nope'));
      await tapKey(tester, 'action-edit-a');
      await tapKey(tester, 'edit-save');
      expect(find.text('Nope'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-save')), findsOneWidget);
    });

    testWidgets('a failed detail load can be retried', (tester) async {
      await pumpManage(tester, [managed('a')]);
      repo.failNext('fetch', apiError('NETWORK_ERROR', 'offline'));
      await tapKey(tester, 'action-edit-a');
      expect(find.text('offline'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-title')), findsOneWidget);
    });
  });

  testWidgets('loads the next page when scrolled near the end', (tester) async {
    await pumpManage(tester, [
      for (var i = 0; i < 6; i++) managed('d$i'),
    ], pageSize: 3);
    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(repo.count('list'), greaterThanOrEqualTo(2));
    expect(find.text('Drawing d5'), findsOneWidget);
  });
}
