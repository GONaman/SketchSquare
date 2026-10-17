import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';

import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';

void main() {
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows categories and the latest drawings feed', (tester) async {
    tallView(tester);
    final repo = FakeDrawingsRepository(
      categories: const [
        CategoryRef(id: 'c1', name: 'Residential', slug: 'residential'),
      ],
      searchPages: [
        [summary('d1', title: 'Corner villa')],
      ],
    );
    await pumpApp(tester, overrides: discoveryFakes(drawings: repo));

    expect(find.text('Residential'), findsOneWidget);
    expect(find.text('Request a category'), findsOneWidget);
    expect(find.text('Corner villa'), findsOneWidget);
    expect(repo.searchCalls.first.query.sort, DrawingSort.newest);
  });

  testWidgets('plot-size search validates before navigating', (tester) async {
    tallView(tester);
    final repo = FakeDrawingsRepository();
    await pumpApp(tester, overrides: discoveryFakes(drawings: repo));
    final calls = repo.searchCalls.length;

    await tester.tap(find.byKey(const Key('plot-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('Length is required'), findsOneWidget);
    expect(find.byKey(const Key('search-field')), findsNothing);
    expect(repo.searchCalls.length, calls);
  });

  testWidgets('a valid plot size opens search with width, length and unit', (
    tester,
  ) async {
    tallView(tester);
    final repo = FakeDrawingsRepository();
    await pumpApp(tester, overrides: discoveryFakes(drawings: repo));

    await tester.enterText(find.byKey(const Key('plot-length')), '40');
    await tester.enterText(find.byKey(const Key('plot-breadth')), '30');
    await tester.tap(find.byKey(const Key('plot-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-field')), findsOneWidget);
    final q = repo.searchCalls.last.query;
    expect(q.length, 40);
    expect(q.breadth, 30);
    expect(q.unit, LengthUnit.ft);
  });

  testWidgets('a category chip opens search filtered by that category', (
    tester,
  ) async {
    tallView(tester);
    final repo = FakeDrawingsRepository(
      categories: const [
        CategoryRef(id: 'c1', name: 'Residential', slug: 'residential'),
      ],
    );
    await pumpApp(tester, overrides: discoveryFakes(drawings: repo));

    await tester.tap(find.widgetWithText(ActionChip, 'Residential'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-field')), findsOneWidget);
    expect(repo.searchCalls.last.query.categoryId, 'c1');
  });

  group('request a category', () {
    testWidgets('rejects an empty name', (tester) async {
      tallView(tester);
      final sent = <String>[];
      final repo = FakeDrawingsRepository(requestedCategories: sent);
      await pumpApp(tester, overrides: discoveryFakes(drawings: repo));

      await tester.tap(find.byKey(const Key('request-category-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category-request-send')));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(find.byKey(const Key('category-request-name')), findsOneWidget);
    });

    testWidgets('sends the trimmed name and confirms', (tester) async {
      tallView(tester);
      final sent = <String>[];
      final repo = FakeDrawingsRepository(requestedCategories: sent);
      await pumpApp(tester, overrides: discoveryFakes(drawings: repo));

      await tester.tap(find.byKey(const Key('request-category-chip')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('category-request-name')),
        '  Farmhouse ',
      );
      await tester.tap(find.byKey(const Key('category-request-send')));
      await tester.pumpAndSettle();

      expect(sent, ['Farmhouse']);
      expect(find.byKey(const Key('category-request-name')), findsNothing);
    });
  });
}
