import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';

import '../helpers/pump_app.dart';

void main() {
  const routes = [
    AppRoutes.signIn,
    AppRoutes.signUp,
    AppRoutes.forgotPassword,
    AppRoutes.terms,
  ];

  for (final route in routes) {
    testWidgets('$route has labelled, >=48dp tap targets', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpApp(tester, signedIn: false);
      container.read(appRouterProvider).go(route);
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  for (final route in [
    AppRoutes.home,
    AppRoutes.featured,
    AppRoutes.upload,
    AppRoutes.basket,
    AppRoutes.profile,
    AppRoutes.settings,
  ]) {
    testWidgets('$route has labelled, >=48dp tap targets', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpApp(tester);
      container.read(appRouterProvider).go(route);
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
