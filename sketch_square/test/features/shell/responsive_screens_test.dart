import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/wallet/data/wallet_providers.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';
import '../wallet/fakes.dart';

const _sizes = <String, Size>{
  'phone 390x844': Size(390, 844),
  'tablet 820x1180': Size(820, 1180),
  'desktop 1440x900': Size(1440, 900),
};

void main() {
  for (final entry in _sizes.entries) {
    final size = entry.value;
    group(entry.key, () {
      testWidgets('home lays out without overflow', (tester) async {
        await pumpApp(tester, size: size, overrides: discoveryFakes());
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-search-entry')), findsOneWidget);
        expect(find.byKey(const Key('plot-search-button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('search lays out without overflow', (tester) async {
        final container = await pumpApp(
          tester,
          size: size,
          overrides: discoveryFakes(),
        );
        container.read(appRouterProvider).go('/home/search');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('search-field')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('drawing detail lays out without overflow', (tester) async {
        final container = await pumpApp(
          tester,
          size: size,
          overrides: discoveryFakes(),
        );
        await precacheGalleryImage(tester);
        container.read(appRouterProvider).go('/home/drawing/d1');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('detail-title')), findsOneWidget);
        expect(find.byKey(const Key('bar-buy-now')), findsOneWidget);
        // Two columns only on desktop: the purchase action sits in a card.
        expect(
          find.byKey(const Key('detail-purchase-card')),
          size.width > 1024 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('sign-in lays out without overflow', (tester) async {
        await pumpApp(tester, size: size, signedIn: false);
        await tester.pumpAndSettle();
        expect(find.text('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('wallet lays out without overflow', (tester) async {
        final container = await pumpApp(
          tester,
          size: size,
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(user: stubUser),
            ),
            walletRepositoryProvider.overrideWithValue(
              FakeWalletRepository(
                ledger: [fakeLedgerEntry(1, description: 'Modern Villa')],
              ),
            ),
          ],
        );
        final router = container.read(appRouterProvider);
        router.go(AppRoutes.profile);
        await tester.pumpAndSettle();
        router.push(AppRoutes.wallet);
        await tester.pumpAndSettle();
        expect(find.text('Modern Villa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('desktop plot-size hero is one capped row', (tester) async {
    await pumpApp(
      tester,
      size: const Size(1440, 900),
      overrides: discoveryFakes(),
    );
    await tester.pumpAndSettle();
    final length = tester.getRect(find.byKey(const Key('plot-length')));
    final button = tester.getRect(find.byKey(const Key('plot-search-button')));
    expect((length.center.dy - button.center.dy).abs(), lessThan(8));
    expect(button.right - length.left, lessThanOrEqualTo(720));
  });
}
