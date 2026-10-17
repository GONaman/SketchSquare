import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/layout/layout.dart';
import 'package:sketch_square/core/router/route_content_width.dart';

import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';

void main() {
  test('content width by route', () {
    expect(contentWidthForPath('/home'), ContentWidth.browse);
    expect(contentWidthForPath('/home/search'), ContentWidth.browse);
    expect(contentWidthForPath('/featured/drawing/d1'), ContentWidth.browse);
    expect(contentWidthForPath('/profile/favorites'), ContentWidth.browse);
    expect(contentWidthForPath('/profile'), ContentWidth.list);
    expect(contentWidthForPath('/basket'), ContentWidth.list);
    expect(contentWidthForPath('/basket/checkout'), ContentWidth.form);
    expect(contentWidthForPath('/upload'), ContentWidth.form);
    expect(contentWidthForPath('/profile/wallet/payouts'), ContentWidth.form);
    expect(contentWidthForPath('/manage-drawings'), ContentWidth.list);
  });

  testWidgets('tablet width swaps the bottom bar for a navigation rail', (
    tester,
  ) async {
    await pumpApp(
      tester,
      size: const Size(820, 1180),
      overrides: discoveryFakes(),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('nav-rail')), findsOneWidget);
    expect(find.byKey(const Key('top-nav')), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('nav-rail')),
        matching: find.text('Featured'),
      ),
    );
    await tester.pumpAndSettle();
    expect(inAppBar('Featured'), findsOneWidget);
  });

  testWidgets('landscape phone height keeps the rail usable', (tester) async {
    await pumpApp(
      tester,
      size: const Size(844, 390),
      overrides: discoveryFakes(),
    );
    expect(find.byKey(const Key('nav-rail')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop width shows a top navigation bar', (tester) async {
    await pumpApp(
      tester,
      size: const Size(1440, 900),
      overrides: discoveryFakes(),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('top-nav')), findsOneWidget);

    await tester.tap(find.byKey(const Key('top-nav-featured')));
    await tester.pumpAndSettle();
    expect(inAppBar('Featured'), findsOneWidget);

    await tester.tap(find.byKey(const Key('top-nav-basket')));
    await tester.pumpAndSettle();
    expect(inAppBar('Basket'), findsOneWidget);

    await tester.tap(find.byKey(const Key('top-nav-brand')));
    await tester.pumpAndSettle();
    expect(inAppBar('Home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('top-nav-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-field')), findsOneWidget);
  });

  testWidgets('content is capped and centred on a wide window', (tester) async {
    await pumpApp(
      tester,
      size: const Size(1900, 1000),
      overrides: discoveryFakes(),
    );
    final rect = tester.getRect(find.byKey(const Key('home-search-entry')));
    expect(rect.width, lessThanOrEqualTo(Breakpoints.browseMaxWidth));
    expect(rect.center.dx, 950);
  });
}
