import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/architects/domain/architect_profile.dart';
import 'package:sketch_square/features/architects/domain/architect_summary.dart';
import 'package:sketch_square/features/drawings/domain/city_count.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';

import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';

void main() {
  TopArchitect top(String id, String name) => TopArchitect(
    architect: ArchitectSummary.fromJson(architectJson(id: id, name: name)),
    drawingCount: 3,
  );

  Future<void> openFeatured(
    WidgetTester tester, {
    FakeDrawingsRepository? drawings,
    FakeArchitectsRepository? architects,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      overrides: discoveryFakes(drawings: drawings, architects: architects),
    );
    await precacheGalleryImage(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Featured'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists top architects and highest-rated drawings', (
    tester,
  ) async {
    final drawings = FakeDrawingsRepository(
      searchPages: [
        [summary('d1', title: 'Star villa')],
      ],
    );
    await openFeatured(
      tester,
      drawings: drawings,
      architects: FakeArchitectsRepository(topList: [top('a1', 'Asha Rao')]),
    );

    expect(inAppBar('Featured'), findsOneWidget);
    expect(find.byKey(const Key('top-architect-a1')), findsOneWidget);
    expect(find.text('Star villa'), findsOneWidget);
    expect(
      drawings.searchCalls.any(
        (c) => c.query.sort == DrawingSort.drawingRating,
      ),
      isTrue,
    );
  });

  testWidgets('shows a message when no architect qualifies yet', (
    tester,
  ) async {
    await openFeatured(tester);

    expect(find.byKey(const Key('top-architects-empty')), findsOneWidget);
    expect(find.text('Nothing featured yet'), findsOneWidget);
  });

  testWidgets('choosing a city filters architects and drawings', (
    tester,
  ) async {
    final drawings = FakeDrawingsRepository(
      cities: const [
        CityCount(city: 'Pune', count: 4),
        CityCount(city: 'Mumbai', count: 2),
      ],
    );
    final architects = FakeArchitectsRepository();
    await openFeatured(tester, drawings: drawings, architects: architects);
    expect(architects.topCities, [null]);

    await tester.tap(find.byKey(const Key('city-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mumbai').last);
    await tester.pumpAndSettle();

    expect(architects.topCities.last, 'Mumbai');
    final last = drawings.searchCalls.last.query;
    expect(last.cities, ['Mumbai']);
    expect(last.sort, DrawingSort.drawingRating);
  });

  testWidgets('tapping a top architect opens the profile', (tester) async {
    await openFeatured(
      tester,
      architects: FakeArchitectsRepository(topList: [top('a1', 'Asha Rao')]),
    );

    await tester.tap(find.byKey(const Key('top-architect-a1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('architect-name')), findsOneWidget);
  });

  testWidgets('tapping a drawing opens the detail inside the Featured tab', (
    tester,
  ) async {
    await openFeatured(
      tester,
      drawings: FakeDrawingsRepository(
        searchPages: [
          [summary('d1', title: 'Star villa')],
        ],
      ),
    );

    await tester.tap(find.text('Star villa'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-title')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a failing top-architects call can be retried', (tester) async {
    final architects = _FlakyArchitects();
    await openFeatured(tester, architects: architects);
    expect(find.text('Unable to reach the server.'), findsOneWidget);

    architects.fail = false;
    await tester.tap(find.byKey(const Key('top-architects-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('top-architects-empty')), findsOneWidget);
  });
}

class _FlakyArchitects extends FakeArchitectsRepository {
  bool fail = true;

  @override
  Future<List<TopArchitect>> top({String? city}) async {
    if (fail) {
      throw const ApiException(
        code: ApiErrorCodes.network,
        message: 'Unable to reach the server.',
      );
    }
    return super.top(city: city);
  }
}
