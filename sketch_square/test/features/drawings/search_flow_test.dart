import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/features/drawings/domain/city_count.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';
import 'package:sketch_square/features/drawings/presentation/search_screen.dart';

import '../../helpers/pump_app.dart';
import 'fixtures.dart';

const _residential = CategoryRef(
  id: 'c1',
  name: 'Residential',
  slug: 'residential',
);

/// Cursors requested by the Search screen (the Home feed below it uses `newest`).
List<String?> _searchCursors(FakeDrawingsRepository repo) => [
  for (final c in repo.searchCalls)
    if (c.query.sort == DrawingSort.relevance) c.cursor,
];

void main() {
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // The load-more spinner animates forever while more pages exist, so
  // pumpAndSettle would time out; advance time manually instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openSearch(
    WidgetTester tester,
    FakeDrawingsRepository repo, [
    String query = '',
  ]) async {
    final container = await pumpApp(
      tester,
      overrides: discoveryFakes(drawings: repo),
    );
    container.read(appRouterProvider).go('/home/search$query');
    await settle(tester);
  }

  group('Search screen', () {
    testWidgets('debounces the text query before searching', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo);
      final before = repo.searchCalls.length;

      await tester.enterText(find.byKey(const Key('search-field')), 'vil');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byKey(const Key('search-field')), 'villa');
      await tester.pump(const Duration(milliseconds: 399));
      expect(repo.searchCalls.length, before);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      expect(repo.searchCalls.length, before + 1);
      expect(repo.searchCalls.last.query.q, 'villa');
    });

    testWidgets('reads the whole query from the URL', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        categories: [_residential],
        searchPages: [
          [summary('d1', sizeMatch: 1)],
        ],
      );
      await openSearch(
        tester,
        repo,
        '?q=villa&length=30&breadth=40&tolerancePct=15&categoryId=c1'
        '&city=Pune&priceType=paid&sort=price_asc',
      );
      final q = repo.searchCalls.last.query;
      expect(q.q, 'villa');
      expect((q.length, q.breadth, q.tolerancePct), (30, 40, 15));
      expect(q.cities, ['Pune']);
      expect(q.priceType, PriceType.paid);
      expect(q.sort, DrawingSort.priceAsc);
      // Chips: size, category, city, price type.
      expect(find.widgetWithText(InputChip, '30×40 ft ±15%'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Residential'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Pune'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Paid'), findsOneWidget);
      expect(find.text('Exact match'), findsOneWidget);
    });

    testWidgets('removing a chip drops just that filter', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo, '?city=Pune&city=Goa&priceType=free');

      await tester.tap(find.byTooltip('Remove Pune'));
      await tester.pumpAndSettle();

      final q = repo.searchCalls.last.query;
      expect(q.cities, ['Goa']);
      expect(q.priceType, PriceType.free);
      expect(find.widgetWithText(InputChip, 'Pune'), findsNothing);
    });

    testWidgets('sort menu changes the sort', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo);

      await tester.tap(find.byKey(const Key('sort-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<DrawingSort>,
          'Price: high to low',
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.searchCalls.last.query.sort, DrawingSort.priceDesc);
    });

    testWidgets('infinite scroll loads the next page by cursor', (
      tester,
    ) async {
      // Short viewport so the footer is off-screen until we scroll.
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [for (var i = 0; i < 16; i++) summary('a$i', title: 'First $i')],
          [for (var i = 0; i < 16; i++) summary('b$i', title: 'Second $i')],
        ],
      );
      await openSearch(tester, repo);
      expect(_searchCursors(repo), [null]);
      expect(find.text('Second 0'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);

      expect(_searchCursors(repo), [null, 'p1']);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      expect(find.text('Second 15'), findsOneWidget);
      // No third request: the last page had no nextCursor.
      expect(_searchCursors(repo), hasLength(2));
    });

    testWidgets('a failed next page shows retry and does not loop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FlakySecondPage(
        first: [for (var i = 0; i < 16; i++) summary('a$i', title: 'First $i')],
        second: [summary('b0', title: 'Second 0')],
      );
      await openSearch(tester, repo);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      expect(find.textContaining('Retry'), findsOneWidget);
      final calls = repo.searchCalls.length;
      await tester.pump(const Duration(seconds: 1));
      expect(repo.searchCalls.length, calls);

      repo.failSecond = false;
      await tester.tap(find.textContaining('Retry'));
      await settle(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      expect(find.text('Second 0'), findsOneWidget);
    });

    testWidgets('shows skeletons while loading', (tester) async {
      tallView(tester);
      final gate = Completer<void>();
      final repo = _GatedRepository(gate.future)
        ..searchPages = [
          [summary('d1')],
        ];
      final container = await pumpApp(
        tester,
        overrides: discoveryFakes(drawings: repo),
      );
      container.read(appRouterProvider).go('/home/search');
      await tester.pump();
      expect(find.byKey(const Key('drawing-grid-skeleton')), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drawing-grid-skeleton')), findsNothing);
    });

    testWidgets('empty state offers to clear filters', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository();
      await openSearch(tester, repo, '?city=Pune&q=zzz');
      expect(find.text('No drawings found'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-filters')));
      await tester.pumpAndSettle();
      expect(repo.searchCalls.last.query.cities, isEmpty);
      expect(repo.searchCalls.last.query.q, 'zzz');
    });

    testWidgets('plot-specific empty state widens the tolerance in one tap', (
      tester,
    ) async {
      tallView(tester);
      final repo = FakeDrawingsRepository();
      await openSearch(tester, repo, '?length=30&breadth=40');
      expect(find.text('No drawings near 30×40 ft'), findsOneWidget);

      await tester.tap(find.byKey(const Key('widen-tolerance')));
      await tester.pumpAndSettle();
      expect(repo.searchCalls.last.query.tolerancePct, 20);
      expect(repo.searchCalls.last.query.length, 30);
    });

    testWidgets('at max tolerance the empty state offers to clear the size', (
      tester,
    ) async {
      tallView(tester);
      final repo = FakeDrawingsRepository();
      await openSearch(tester, repo, '?length=30&breadth=40&tolerancePct=50');
      expect(find.byKey(const Key('widen-tolerance')), findsNothing);

      await tester.tap(find.byKey(const Key('clear-plot-size')));
      await tester.pumpAndSettle();
      expect(repo.searchCalls.last.query.hasPlotSize, isFalse);
    });

    testWidgets('shows the result count and a clear-all chip', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1'), summary('d2')],
        ],
      );
      await openSearch(tester, repo, '?city=Pune&priceType=free');
      expect(find.text('2 drawings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-all-filters')));
      await tester.pumpAndSettle();
      expect(repo.searchCalls.last.query.activeFilterCount, 0);
    });

    testWidgets('error state retries the search', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1', title: 'Recovered')],
        ],
        searchError: const ApiException(
          code: ApiErrorCodes.network,
          message: 'Unable to reach the server.',
        ),
      );
      await openSearch(tester, repo);
      expect(find.text('Unable to reach the server.'), findsOneWidget);

      repo.searchError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered'), findsOneWidget);
    });
  });

  group('Filters sheet', () {
    testWidgets('applies plot size, category, city, rating and price type', (
      tester,
    ) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        categories: [_residential],
        cities: [const CityCount(city: 'Pune', count: 3)],
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo);

      await tester.tap(find.byKey(const Key('filters-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('plot-length')), '30');
      await tester.enterText(find.byKey(const Key('plot-breadth')), '40');
      await tester.tap(find.text('Residential'));
      await tester.tap(find.widgetWithText(FilterChip, 'Pune'));
      await tester.tap(find.byKey(const Key('drawing-rating-4.0')));
      await tester.tap(find.byKey(const Key('architect-rating-3.5')));
      await tester.tap(find.text('Paid'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();

      final q = repo.searchCalls.last.query;
      expect((q.length, q.breadth, q.unit), (30, 40, LengthUnit.ft));
      expect(q.categoryId, 'c1');
      expect(q.cities, ['Pune']);
      expect(q.minDrawingRating, 4);
      expect(q.minArchitectRating, 3.5);
      expect(q.priceType, PriceType.paid);
      expect(find.byKey(const Key('filters-button')), findsOneWidget);
      expect(find.text('6'), findsOneWidget); // filter-count badge
    });

    testWidgets('invalid plot size keeps the sheet open with errors', (
      tester,
    ) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo);
      final before = repo.searchCalls.length;

      await tester.tap(find.byKey(const Key('filters-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('plot-length')), '40');
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();

      expect(find.text('Breadth is required'), findsOneWidget);
      expect(find.byKey(const Key('filters-apply')), findsOneWidget);
      expect(repo.searchCalls.length, before);
    });

    testWidgets('reset clears filters but keeps the text query', (
      tester,
    ) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo, '?q=villa&city=Pune&priceType=free');

      await tester.tap(find.byKey(const Key('filters-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters-reset')));
      await tester.pumpAndSettle();

      final q = repo.searchCalls.last.query;
      expect(q, const DrawingSearchQuery(q: 'villa'));
    });

    testWidgets('free-only disables the price slider', (tester) async {
      tallView(tester);
      final repo = FakeDrawingsRepository(
        searchPages: [
          [summary('d1')],
        ],
      );
      await openSearch(tester, repo, '?priceType=free');
      await tester.tap(find.byKey(const Key('filters-button')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RangeSlider>(find.byKey(const Key('price-range')))
            .onChanged,
        isNull,
      );
    });
  });

  test('searchDebounce is a short delay', () {
    expect(searchDebounce, const Duration(milliseconds: 400));
  });
}

class _FlakySecondPage extends FakeDrawingsRepository {
  _FlakySecondPage({
    required List<DrawingSummary> first,
    required List<DrawingSummary> second,
  }) : super(searchPages: [first, second]);

  bool failSecond = true;

  @override
  Future<CursorPage<DrawingSummary>> search(
    DrawingSearchQuery query, {
    String? cursor,
    int limit = 20,
  }) async {
    if (cursor != null && failSecond) {
      searchCalls.add((query: query, cursor: cursor));
      throw const ApiException(code: ApiErrorCodes.network, message: 'down');
    }
    return super.search(query, cursor: cursor, limit: limit);
  }
}

class _GatedRepository extends FakeDrawingsRepository {
  _GatedRepository(this.gate);

  final Future<void> gate;

  @override
  Future<CursorPage<DrawingSummary>> search(
    DrawingSearchQuery query, {
    String? cursor,
    int limit = 20,
  }) async {
    await gate;
    return super.search(query, cursor: cursor, limit: limit);
  }
}
