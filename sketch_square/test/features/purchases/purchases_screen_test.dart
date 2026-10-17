import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/purchases/data/purchases_providers.dart';
import 'package:sketch_square/features/purchases/domain/purchase_models.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

void main() {
  late FakePurchasesRepository purchases;
  late FakeFileDownloader downloader;
  late FakeFileHandler handler;
  late FakeReviewRepository reviews;
  late FakeAuthRepository auth;

  setUp(() {
    purchases = FakePurchasesRepository(
      items: [
        fakePurchase(id: 'd1', title: 'Modern Villa'),
        fakePurchase(id: 'd2', title: 'Free Duplex', kind: PurchaseKind.free),
      ],
    );
    downloader = FakeFileDownloader();
    handler = FakeFileHandler();
    reviews = FakeReviewRepository();
    auth = FakeAuthRepository(
      user: stubUser.copyWith(freeDownloadsUsed: 3, freeDownloadLimit: 20),
    );
  });

  Future<void> openPurchases(WidgetTester tester) async {
    final container = await pumpApp(
      tester,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        purchasesRepositoryProvider.overrideWithValue(purchases),
        fileDownloaderProvider.overrideWithValue(downloader),
        fileHandlerProvider.overrideWithValue(handler),
        reviewRepositoryProvider.overrideWithValue(reviews),
      ],
    );
    container.read(appRouterProvider).go(AppRoutes.purchases);
    await tester.pumpAndSettle();
  }

  testWidgets('lists purchases with kind, price and the free quota', (
    tester,
  ) async {
    await openPurchases(tester);

    expect(find.text('My purchases'), findsOneWidget);
    expect(find.text('Modern Villa'), findsOneWidget);
    expect(find.text('Free Duplex'), findsOneWidget);
    expect(find.textContaining('₹1,500 ·'), findsOneWidget);
    expect(find.textContaining('Free · '), findsOneWidget);
    expect(find.text('Free downloads: 3 of 20 used'), findsOneWidget);
  });

  testWidgets('download then open and share the saved file', (tester) async {
    await openPurchases(tester);

    await tester.tap(find.byKey(const Key('download-s-d1')).first);
    await tester.pumpAndSettle();

    expect(purchases.downloads, ['d1/s-d1']);
    expect(downloader.links.single.url, contains('storage.test'));

    await tester.tap(find.byKey(const Key('open-s-d1')).first);
    await tester.tap(find.byKey(const Key('share-s-d1')).first);
    await tester.pumpAndSettle();
    expect(handler.opened, ['/files/s-d1.pdf']);
    expect(handler.shared, ['/files/s-d1.pdf']);
  });

  testWidgets('free download refreshes the user for the quota indicator', (
    tester,
  ) async {
    await openPurchases(tester);
    auth.user = auth.user.copyWith(freeDownloadsUsed: 4);

    await tester.tap(find.byKey(const Key('download-s-d2')).last);
    await tester.pumpAndSettle();

    expect(find.text('Free downloads: 4 of 20 used'), findsOneWidget);
  });

  testWidgets('quota reached shows the limit message and keeps retry', (
    tester,
  ) async {
    purchases.downloadError = const ApiException(
      code: ApiErrorCodes.freeLimitReached,
      message: 'limit',
      statusCode: 403,
    );
    await openPurchases(tester);

    await tester.tap(find.byKey(const Key('download-s-d2')).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Free download limit reached'), findsOneWidget);
    expect(find.byKey(const Key('download-s-d2')), findsOneWidget);
  });

  testWidgets('rating: star required, then submit sends the review', (
    tester,
  ) async {
    await openPurchases(tester);

    await tester.tap(find.text('Rate').first);
    await tester.pumpAndSettle();
    expect(find.text('Rate this drawing'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit review'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('star-4')));
    await tester.enterText(find.byType(TextField), 'Lovely plan');
    await tester.pump();
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(reviews.submitted.single.drawingId, 'd1');
    expect(reviews.submitted.single.rating, 4);
    expect(reviews.submitted.single.comment, 'Lovely plan');
    expect(find.text('Thanks for your review'), findsOneWidget);
  });

  testWidgets('review errors are shown inline and the sheet stays open', (
    tester,
  ) async {
    reviews.error = const ApiException(
      code: ApiErrorCodes.forbidden,
      message: 'You cannot review this drawing',
      statusCode: 403,
    );
    await openPurchases(tester);

    await tester.tap(find.text('Rate').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('star-5')));
    await tester.pump();
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(find.text('You cannot review this drawing'), findsOneWidget);
    expect(find.text('Submit review'), findsOneWidget);
  });

  testWidgets('empty library shows the empty state', (tester) async {
    purchases.items = [];
    await openPurchases(tester);
    expect(find.text('No purchases yet'), findsOneWidget);
  });

  testWidgets('load error offers retry', (tester) async {
    purchases.listError = offline;
    await openPurchases(tester);
    expect(find.text('No connection'), findsOneWidget);

    purchases.listError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Modern Villa'), findsOneWidget);
  });
}
