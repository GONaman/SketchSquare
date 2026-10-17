import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/router/app_router.dart';

import '../../helpers/pump_app.dart';

void main() {
  const tabs = ['Home', 'Featured', 'Upload', 'Basket', 'Profile'];

  Finder navLabel(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('shell shows the five tabs and starts on Home', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in tabs) {
      expect(navLabel(label), findsOneWidget, reason: label);
    }
    expect(inAppBar('Home'), findsOneWidget);
  });

  testWidgets('tapping a tab switches the visible screen', (tester) async {
    await pumpApp(tester);

    for (final label in tabs) {
      await tester.tap(navLabel(label));
      await tester.pumpAndSettle();
      expect(inAppBar(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('each tab keeps its own navigation stack', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);

    Future<void> openTab(String label) async {
      await tester.tap(navLabel(label));
      await tester.pumpAndSettle();
    }

    router.go('/home/details');
    await tester.pumpAndSettle();
    expect(inAppBar('Details'), findsOneWidget);

    await openTab('Featured');
    expect(inAppBar('Featured'), findsOneWidget);

    // Back on Home the pushed details page is still there.
    await openTab('Home');
    expect(inAppBar('Details'), findsOneWidget);

    // Re-tapping the active tab pops it back to its root.
    await openTab('Home');
    expect(inAppBar('Home'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
