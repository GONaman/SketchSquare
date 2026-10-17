import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/widgets/widgets.dart';
import 'package:sketch_square/features/admin/domain/admin_purchase.dart';
import 'package:sketch_square/features/admin/presentation/admin_refund_detail_screen.dart';
import 'package:sketch_square/features/admin/presentation/refunds_providers.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';

import '../../helpers/auth_test_utils.dart';
import '../../helpers/fake_admin_refunds.dart';
import '../../helpers/pump_app.dart';

final _admin = stubUser.copyWith(role: UserRole.admin);

Future<void> _open(
  WidgetTester tester,
  FakeAdminRefundsRepository repo, {
  String path = '${AppRoutes.admin}/refunds',
  User? user,
}) async {
  useTallScreen(tester);
  final container = await pumpApp(
    tester,
    user: user ?? _admin,
    overrides: [adminRefundsRepositoryProvider.overrideWithValue(repo)],
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
}

Future<void> _tapRefundAndConfirm(WidgetTester tester, String reason) async {
  await tester.tap(find.byKey(const Key('refund-button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('refund-reason-field')), reason);
  await tester.tap(find.byKey(const Key('refund-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  late FakeAdminRefundsRepository repo;

  setUp(() {
    repo = FakeAdminRefundsRepository(
      items: [
        makeAdminPurchase('p1'),
        makeAdminPurchase('p2', title: 'Cottage', buyer: 'Carl Customer'),
        makeAdminPurchase(
          'p3',
          title: 'Loft',
          status: PurchaseStatus.refunded,
          refund: makeAdminRefund(),
        ),
      ],
    );
  });

  group('list', () {
    testWidgets('is reachable from the admin home and shows purchases', (
      tester,
    ) async {
      await _open(tester, repo, path: AppRoutes.admin);
      await tester.tap(find.byKey(const Key('open-refunds')));
      await tester.pumpAndSettle();

      expect(inAppBar('Refunds'), findsOneWidget);
      expect(find.text('Modern Villa'), findsOneWidget);
      expect(find.text('Cottage'), findsOneWidget);
      expect(find.text('Loft'), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Refunded'), findsOneWidget);
    });

    testWidgets('debounced search and status filter hit the repository', (
      tester,
    ) async {
      await _open(tester, repo);
      expect(repo.queries.length, 1);

      await tester.enterText(find.byKey(const Key('refunds-search')), 'carl');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.queries.length, 1, reason: 'still debouncing');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repo.queries.last.q, 'carl');
      expect(find.text('Cottage'), findsOneWidget);
      expect(find.text('Modern Villa'), findsNothing);

      await tester.tap(find.byKey(const Key('refunds-search-clear')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('refunds-filter-REFUNDED')));
      await tester.pumpAndSettle();

      expect(repo.queries.last.status, PurchaseStatus.refunded);
      expect(find.text('Loft'), findsOneWidget);
      expect(find.text('Modern Villa'), findsNothing);
    });

    testWidgets('empty result shows an empty state', (tester) async {
      repo.items.clear();
      await _open(tester, repo);
      expect(find.text('No purchases found'), findsOneWidget);
    });

    testWidgets('load failure offers retry', (tester) async {
      repo.listError = const ApiException(
        code: ApiErrorCodes.network,
        message: 'You appear to be offline.',
      );
      await _open(tester, repo);
      expect(find.text('You appear to be offline.'), findsOneWidget);

      repo.listError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Modern Villa'), findsOneWidget);
    });

    testWidgets('loads the next page when scrolled to the end', (tester) async {
      repo = FakeAdminRefundsRepository(
        items: [
          for (var i = 0; i < 5; i++) makeAdminPurchase('p$i', title: 'D$i'),
        ],
        pageSize: 3,
      );
      await _open(tester, repo);
      expect(repo.queries.map((q) => q.cursor), [null, '3']);
      expect(find.text('D4'), findsOneWidget);
    });
  });

  group('detail and refund', () {
    testWidgets('shows purchase details and refunds with a reason', (
      tester,
    ) async {
      await _open(tester, repo, path: adminRefundPathFor('p1'));

      expect(find.text('Modern Villa'), findsOneWidget);
      expect(find.byKey(const Key('seller-balance')), findsOneWidget);
      expect(find.text('Refund ₹500'), findsOneWidget);

      await _tapRefundAndConfirm(tester, '  Buyer got a duplicate  ');

      expect(repo.refunds, [(id: 'p1', reason: 'Buyer got a duplicate')]);
      expect(find.text('Refund of ₹500 issued.'), findsOneWidget);
      expect(find.byKey(const Key('refund-button')), findsNothing);
      expect(find.byKey(const Key('refund-reason')), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Refunded'), findsOneWidget);
    });

    testWidgets('a reason is required and cancel does nothing', (tester) async {
      await _open(tester, repo, path: adminRefundPathFor('p1'));

      await tester.tap(find.byKey(const Key('refund-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('refund-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a reason'), findsOneWidget);
      expect(repo.refunds, isEmpty);

      await tester.tap(find.byKey(const Key('refund-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('refund-reason-field')), findsNothing);
      expect(repo.refunds, isEmpty);
    });

    testWidgets('warns when the seller balance would go negative', (
      tester,
    ) async {
      repo.sellerBalance = 10000;
      await _open(tester, repo, path: adminRefundPathFor('p1'));
      expect(find.byKey(const Key('negative-balance-warning')), findsOneWidget);
      expect(find.textContaining('-₹350'), findsOneWidget);
    });

    testWidgets('no warning when the balance covers the refund', (
      tester,
    ) async {
      await _open(tester, repo, path: adminRefundPathFor('p1'));
      expect(find.byKey(const Key('negative-balance-warning')), findsNothing);
    });

    testWidgets('refunded purchases show the refund and no refund button', (
      tester,
    ) async {
      await _open(tester, repo, path: adminRefundPathFor('p3'));
      expect(find.byKey(const Key('refund-button')), findsNothing);
      expect(find.byKey(const Key('refund-retry')), findsNothing);
      expect(find.text('Duplicate purchase'), findsOneWidget);
      expect(find.textContaining('Succeeded (rfnd_1)'), findsOneWidget);
    });

    testWidgets('server errors are shown and the purchase stays refundable', (
      tester,
    ) async {
      repo.refundError = const ApiException(
        code: ApiErrorCodes.conflict,
        message: 'Purchase is not refundable',
      );
      await _open(tester, repo, path: adminRefundPathFor('p1'));
      await _tapRefundAndConfirm(tester, 'Because');

      expect(find.text('Purchase is not refundable'), findsOneWidget);
      expect(find.byKey(const Key('refund-button')), findsOneWidget);
    });

    testWidgets('a failed gateway refund can be retried', (tester) async {
      repo.nextProviderStatus = RefundProviderStatus.failed;
      await _open(tester, repo, path: adminRefundPathFor('p1'));
      await _tapRefundAndConfirm(tester, 'Because');

      expect(find.textContaining('gateway refund failed'), findsOneWidget);
      expect(find.textContaining('gateway down'), findsOneWidget);

      repo.nextProviderStatus = RefundProviderStatus.succeeded;
      await tester.tap(find.byKey(const Key('refund-retry')));
      await tester.pumpAndSettle();

      expect(repo.refunds.last, (id: 'p1', reason: 'Because'));
      expect(find.byKey(const Key('refund-retry')), findsNothing);
      expect(find.textContaining('Succeeded'), findsOneWidget);
    });

    testWidgets('detail load failure offers retry', (tester) async {
      repo.detailError = const ApiException(
        code: ApiErrorCodes.notFound,
        message: 'Purchase not found',
      );
      await _open(tester, repo, path: adminRefundPathFor('p1'));
      expect(find.text('Purchase not found'), findsOneWidget);
    });
  });

  testWidgets('non-admins cannot open the refunds screen', (tester) async {
    await _open(tester, repo, user: stubUser);
    expect(inAppBar('Refunds'), findsNothing);
  });

  testWidgets('list and detail fit a small phone at 1.3x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final container = await pumpApp(
      tester,
      user: _admin,
      overrides: [adminRefundsRepositoryProvider.overrideWithValue(repo)],
    );
    final router = container.read(appRouterProvider);
    router.go('${AppRoutes.admin}/refunds');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final id in ['p1', 'p3']) {
      router.go(adminRefundPathFor(id));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  test('validateRefundReason trims and bounds the reason', () {
    expect(validateRefundReason('  '), isNotNull);
    expect(validateRefundReason('ab'), isNotNull);
    expect(validateRefundReason(' abc '), isNull);
    expect(validateRefundReason('x' * 501), isNotNull);
  });
}

String adminRefundPathFor(String id) => '${AppRoutes.admin}/refunds/$id';
