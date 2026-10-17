import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/features/architects/domain/architect_profile.dart';
import 'package:sketch_square/features/architects/domain/architect_summary.dart';

import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    FakeArchitectsRepository architects,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await pumpApp(
      tester,
      overrides: discoveryFakes(architects: architects),
    );
    await precacheGalleryImage(tester);
    container.read(appRouterProvider).go('/home/architect/a1');
    await tester.pumpAndSettle();
  }

  ArchitectProfile profile({
    required List<String> ids,
    String? nextCursor,
    int ratingCount = 12,
  }) => ArchitectProfile(
    architect: ArchitectSummary.fromJson({
      ...architectJson(),
      'ratingCount': ratingCount,
    }),
    drawings: CursorPage(
      items: [for (final id in ids) summary(id, title: 'Plan $id')],
      nextCursor: nextCursor,
    ),
  );

  testWidgets('shows the architect header and their drawings', (tester) async {
    await open(tester, FakeArchitectsRepository(profile: profile(ids: ['d1'])));

    expect(find.byKey(const Key('architect-name')), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Pune'), findsWidgets);
    expect(find.textContaining('4.5 (12 ratings)'), findsOneWidget);
    expect(find.text('Plan d1'), findsOneWidget);
  });

  testWidgets('shows no ratings yet for an unrated architect', (tester) async {
    await open(
      tester,
      FakeArchitectsRepository(profile: profile(ids: ['d1'], ratingCount: 0)),
    );

    expect(find.text('No ratings yet'), findsOneWidget);
  });

  testWidgets('shows an empty state without drawings', (tester) async {
    await open(tester, FakeArchitectsRepository(profile: profile(ids: [])));

    expect(find.text('No drawings yet'), findsOneWidget);
  });

  testWidgets('loads further pages of drawings by cursor', (tester) async {
    final repo = FakeArchitectsRepository(
      profile: profile(
        ids: [for (var i = 0; i < 16; i++) 'a$i'],
        nextCursor: 'c1',
      ),
      morePages: [
        CursorPage(items: [summary('z1', title: 'Last plan')]),
      ],
    );
    await open(tester, repo);
    expect(repo.listCursors, isEmpty);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(repo.listCursors, ['c1']);
    expect(find.text('Last plan'), findsOneWidget);
  });

  testWidgets('tapping a drawing opens its detail', (tester) async {
    await open(tester, FakeArchitectsRepository(profile: profile(ids: ['d1'])));

    await tester.tap(find.text('Plan d1'));
    await tester.pumpAndSettle();

    expect(inAppBar('Modern villa'), findsOneWidget);
  });
}
