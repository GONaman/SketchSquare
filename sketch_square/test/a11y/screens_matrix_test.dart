import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/theme/theme_mode_provider.dart';
import 'package:sketch_square/features/architects/domain/architect_profile.dart';
import 'package:sketch_square/features/architects/domain/architect_summary.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/basket/data/basket_providers.dart';
import 'package:sketch_square/features/basket/data/pending_checkout_store.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/presentation/discovery_paths.dart';
import 'package:sketch_square/features/purchases/data/purchases_providers.dart';
import 'package:sketch_square/features/purchases/domain/purchase_models.dart';

import '../features/basket/fakes.dart';
import '../features/drawings/fixtures.dart';
import '../features/purchases/fakes.dart';
import '../helpers/commerce_fixtures.dart';
import '../helpers/pump_app.dart';
import '../helpers/scripted_adapter.dart';

const _longTitle =
    'Contemporary four bedroom courtyard villa with double height living room';

/// Every screen is pumped on a small phone with the largest text scale we
/// support, in both themes. Overflows and build errors surface as exceptions.
const _textScale = 1.3;

void _smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = _textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

/// Anything not faked below fails with a 500, which exercises error states.
Dio _failingDio() {
  return Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = ScriptedAdapter(
      (_) => errorResponse(500, 'INTERNAL', 'boom'),
    );
}

List<Override> _dataOverrides() => [
  dioProvider.overrideWithValue(_failingDio()),
  ...discoveryFakes(
    drawings: FakeDrawingsRepository(
      categories: const [
        CategoryRef(id: 'c1', name: 'Residential', slug: 'residential'),
        CategoryRef(id: 'c2', name: 'Commercial', slug: 'commercial'),
      ],
      searchPages: [
        [
          summary('d1', title: _longTitle, sizeMatch: 0.92),
          summary('d2', title: 'Duplex', isFree: true),
        ],
      ],
    ),
    architects: FakeArchitectsRepository(
      topList: [
        TopArchitect(
          architect: ArchitectSummary.fromJson(architectJson()),
          drawingCount: 12,
        ),
      ],
    ),
  ),
  cartRepositoryProvider.overrideWithValue(
    FakeCartRepository(
      items: [
        fakeDrawing(id: 'd1', title: _longTitle),
        fakeDrawing(id: 'd2', title: 'Duplex', pricePaise: 50050),
      ],
    ),
  ),
  checkoutRepositoryProvider.overrideWithValue(FakeCheckoutRepository()),
  paymentGatewayProvider.overrideWithValue(FakePaymentGateway()),
  pendingCheckoutStoreProvider.overrideWithValue(
    InMemoryPendingCheckoutStore(),
  ),
  purchasesRepositoryProvider.overrideWithValue(
    FakePurchasesRepository(
      items: [
        fakePurchase(id: 'd1', title: _longTitle),
        fakePurchase(id: 'd2', title: 'Free Duplex', kind: PurchaseKind.free),
      ],
    ),
  ),
  fileDownloaderProvider.overrideWithValue(FakeFileDownloader()),
  fileHandlerProvider.overrideWithValue(FakeFileHandler()),
  reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
];

final _signedInRoutes = <String>[
  AppRoutes.home,
  const DiscoveryPaths(AppRoutes.home).search(),
  const DiscoveryPaths(AppRoutes.home).drawing('d1'),
  const DiscoveryPaths(AppRoutes.home).architect('a1'),
  AppRoutes.featured,
  AppRoutes.upload,
  AppRoutes.basket,
  AppRoutes.basketCheckout,
  AppRoutes.profile,
  AppRoutes.profileEdit,
  AppRoutes.settings,
  AppRoutes.purchases,
  AppRoutes.manageDrawings,
  AppRoutes.wallet,
  AppRoutes.walletBank,
  AppRoutes.walletPayouts,
  AppRoutes.terms,
  AppRoutes.privacy,
];

final _signedOutRoutes = <String>[
  AppRoutes.intro,
  AppRoutes.signIn,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
  AppRoutes.terms,
  AppRoutes.privacy,
];

Future<void> _visit(
  WidgetTester tester,
  ProviderContainer container,
  List<String> routes,
) async {
  final router = container.read(appRouterProvider);
  for (final route in routes) {
    router.go(route);
    try {
      await tester.pumpAndSettle();
    } catch (e) {
      fail('$route never settled: $e');
    }
    expect(
      router.routeInformationProvider.value.uri.path,
      Uri.parse(route).path,
      reason: 'redirected away from $route',
    );
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason:
          'build/overflow error on $route: '
          '${error is FlutterError ? error.toStringDeep() : error}',
    );
  }
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    group('${mode.name} theme at text scale $_textScale', () {
      testWidgets('signed-in screens render without exceptions', (
        tester,
      ) async {
        _smallPhone(tester);
        final container = await pumpApp(tester, overrides: _dataOverrides());
        await precacheGalleryImage(tester);
        await container.read(appThemeModeProvider.notifier).set(mode);
        await tester.pumpAndSettle();

        await _visit(tester, container, _signedInRoutes);
      });

      testWidgets('admin screens render without exceptions', (tester) async {
        _smallPhone(tester);
        final container = await pumpApp(
          tester,
          user: stubUser.copyWith(role: UserRole.admin),
          overrides: _dataOverrides(),
        );
        await container.read(appThemeModeProvider.notifier).set(mode);
        await tester.pumpAndSettle();

        await _visit(tester, container, [AppRoutes.admin]);
      });

      testWidgets('pending-verification screen renders', (tester) async {
        _smallPhone(tester);
        final container = await pumpApp(
          tester,
          user: stubUser.copyWith(
            verificationStatus: VerificationStatus.pending,
          ),
          overrides: _dataOverrides(),
        );
        await container.read(appThemeModeProvider.notifier).set(mode);
        await tester.pumpAndSettle();

        await _visit(tester, container, [AppRoutes.verificationPending]);
      });

      testWidgets('signed-out screens render without exceptions', (
        tester,
      ) async {
        _smallPhone(tester);
        final container = await pumpApp(
          tester,
          signedIn: false,
          introSeen: false,
          overrides: _dataOverrides(),
        );
        await container.read(appThemeModeProvider.notifier).set(mode);
        await tester.pumpAndSettle();

        await _visit(tester, container, _signedOutRoutes);
      });
    });
  }
}
