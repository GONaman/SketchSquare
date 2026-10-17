import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/features/drawings/domain/drawing_detail.dart';
import 'package:sketch_square/features/drawings/domain/review.dart';
import 'package:sketch_square/features/drawings/presentation/drawing_purchase_bar.dart';

import '../../helpers/pump_app.dart';
import 'fixtures.dart';

Map<String, dynamic> _viewer({
  bool isOwner = false,
  bool isPurchased = false,
  bool inCart = false,
  bool canDownload = false,
  int? freeLeft,
  bool isFavorite = false,
}) => {
  'isOwner': isOwner,
  'isPurchased': isPurchased,
  'inCart': inCart,
  'canDownload': canDownload,
  'freeDownloadsRemaining': freeLeft,
  'myReview': null,
  'isFavorite': isFavorite,
};

DrawingDetail _detail({
  Map<String, dynamic>? viewer,
  bool isFree = false,
  int pricePaise = 49900,
}) => DrawingDetail.fromJson(
  detailJson(viewer: viewer, isFree: isFree, pricePaise: pricePaise),
);

void main() {
  Future<({FakeDrawingsRepository repo, FakeDrawingActions actions})> open(
    WidgetTester tester, {
    DrawingDetail? detail,
    FakeDrawingsRepository? repo,
    FakeDrawingActions? actions,
    FakeArchitectsRepository? architects,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final r = repo ?? FakeDrawingsRepository(detail: detail);
    final a = actions ?? FakeDrawingActions();
    final container = await pumpApp(
      tester,
      overrides: discoveryFakes(
        drawings: r,
        actions: a,
        architects: architects,
      ),
    );
    await precacheGalleryImage(tester);
    container.read(appRouterProvider).go('/home/drawing/d1');
    await tester.pumpAndSettle();
    return (repo: r, actions: a);
  }

  group('purchaseActionFor', () {
    test('owner wins over everything', () {
      expect(
        purchaseActionFor(
          _detail(viewer: _viewer(isOwner: true, canDownload: true)),
        ),
        PurchaseAction.owner,
      );
    });

    test('download when the server says canDownload', () {
      expect(
        purchaseActionFor(
          _detail(viewer: _viewer(isPurchased: true, canDownload: true)),
        ),
        PurchaseAction.download,
      );
    });

    test('free without quota is blocked, paid is buyable', () {
      expect(
        purchaseActionFor(_detail(isFree: true, pricePaise: 0)),
        PurchaseAction.freeLimitReached,
      );
      expect(purchaseActionFor(_detail()), PurchaseAction.buy);
    });

    test('in basket from the server flag or the local override', () {
      expect(
        purchaseActionFor(_detail(viewer: _viewer(inCart: true))),
        PurchaseAction.inBasket,
      );
      expect(
        purchaseActionFor(_detail(), inCart: true),
        PurchaseAction.inBasket,
      );
    });
  });

  group('Drawing detail screen', () {
    testWidgets('shows metadata, price, description and watermarked gallery', (
      tester,
    ) async {
      await open(tester);

      expect(find.byKey(const Key('detail-title')), findsOneWidget);
      expect(find.text('Modern villa'), findsWidgets);
      expect(find.byKey(const Key('detail-price')), findsOneWidget);
      expect(find.text('₹499'), findsWidgets);
      expect(find.text('40×30.5 ft'), findsOneWidget);
      expect(find.text('Floors'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(find.text('Facing'), findsOneWidget);
      expect(find.text('A spacious family home.'), findsOneWidget);
      expect(find.text('Preview · watermarked'), findsOneWidget);
      // Two preview sheets feed the gallery; the structural sheet is not shown.
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('swiping the gallery moves the indicator', (tester) async {
      await open(tester);

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('locks sheets and hides file names until purchased', (
      tester,
    ) async {
      await open(tester);

      expect(find.byKey(const Key('sheet-locked-s2')), findsOneWidget);
      expect(find.text('structure.pdf'), findsNothing);
      expect(find.text('Included with purchase'), findsOneWidget);
    });

    testWidgets('unlocks sheets for a buyer who can download', (tester) async {
      await open(
        tester,
        detail: _detail(viewer: _viewer(isPurchased: true, canDownload: true)),
      );

      expect(find.byKey(const Key('sheet-open-s2')), findsOneWidget);
      expect(find.text('structure.pdf'), findsOneWidget);
    });

    testWidgets('tapping the architect opens their profile', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('architect-card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('architect-name')), findsOneWidget);
      expect(find.text('Asha Rao'), findsWidgets);
    });

    testWidgets('shows an error with retry when loading fails', (tester) async {
      final repo = FakeDrawingsRepository(
        detailError: const ApiException(
          code: ApiErrorCodes.notFound,
          message: 'Drawing not found.',
        ),
      );
      await open(tester, repo: repo);
      expect(find.text('Drawing not found.'), findsOneWidget);

      repo.detailError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-title')), findsOneWidget);
    });
  });

  group('purchase bar', () {
    testWidgets('add to basket calls the repository and flips to In basket', (
      tester,
    ) async {
      final ctx = await open(tester);
      expect(find.byKey(const Key('bar-price')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bar-add-to-basket')));
      await tester.pumpAndSettle();

      expect(ctx.actions.carted, ['d1']);
      expect(find.byKey(const Key('bar-in-basket')), findsOneWidget);
      expect(find.text('Added to basket'), findsOneWidget);
    });

    testWidgets('buy now adds and opens the basket tab', (tester) async {
      final ctx = await open(tester);

      await tester.tap(find.byKey(const Key('bar-buy-now')));
      await tester.pumpAndSettle();

      expect(ctx.actions.carted, ['d1']);
      expect(inAppBar('Basket'), findsOneWidget);
    });

    testWidgets('a failed add shows the server message and stays buyable', (
      tester,
    ) async {
      final actions =
          FakeDrawingActions()
            ..error = const ApiException(
              code: ApiErrorCodes.conflict,
              message: 'You already own this drawing.',
            );
      await open(tester, actions: actions);

      await tester.tap(find.byKey(const Key('bar-add-to-basket')));
      await tester.pumpAndSettle();

      expect(find.text('You already own this drawing.'), findsOneWidget);
      expect(find.byKey(const Key('bar-add-to-basket')), findsOneWidget);
      expect(find.byKey(const Key('bar-in-basket')), findsNothing);
    });

    testWidgets('owner sees their own drawing, no favorite or purchase', (
      tester,
    ) async {
      await open(tester, detail: _detail(viewer: _viewer(isOwner: true)));

      expect(find.byKey(const Key('bar-owner')), findsOneWidget);
      expect(find.byKey(const Key('favorite-button')), findsNothing);
      expect(find.byKey(const Key('bar-add-to-basket')), findsNothing);
    });

    testWidgets(
      'free drawing with quota offers download with remaining count',
      (tester) async {
        await open(
          tester,
          detail: _detail(
            isFree: true,
            pricePaise: 0,
            viewer: _viewer(canDownload: true, freeLeft: 2),
          ),
        );

        expect(find.text('Download free (2 left)'), findsOneWidget);
      },
    );

    testWidgets('free drawing without quota shows the limit message', (
      tester,
    ) async {
      await open(
        tester,
        detail: _detail(isFree: true, pricePaise: 0, viewer: _viewer()),
      );

      expect(find.byKey(const Key('bar-free-limit')), findsOneWidget);
      expect(find.text('Free download limit reached'), findsOneWidget);
    });

    testWidgets('already in basket from the server shows View basket', (
      tester,
    ) async {
      await open(tester, detail: _detail(viewer: _viewer(inCart: true)));

      expect(find.byKey(const Key('bar-in-basket')), findsOneWidget);
      expect(find.byKey(const Key('bar-add-to-basket')), findsNothing);
    });
  });

  group('favorite', () {
    testWidgets('toggles through the repository', (tester) async {
      final ctx = await open(tester);

      await tester.tap(find.byKey(const Key('favorite-button')));
      await tester.pumpAndSettle();

      expect(ctx.actions.favorites, {'d1': true});
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('favorite-button')));
      await tester.pumpAndSettle();
      expect(ctx.actions.favorites, {'d1': false});
    });

    testWidgets('reverts and reports when the call fails', (tester) async {
      final actions =
          FakeDrawingActions()
            ..error = const ApiException(
              code: ApiErrorCodes.network,
              message: 'Unable to reach the server.',
            );
      await open(tester, actions: actions);

      await tester.tap(find.byKey(const Key('favorite-button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('Unable to reach the server.'), findsOneWidget);
    });
  });

  group('reviews', () {
    testWidgets('shows the first page and loads more by cursor', (
      tester,
    ) async {
      final repo = FakeDrawingsRepository(
          detail: DrawingDetail.fromJson({
            ...detailJson(),
            'reviews': {
              'items': [reviewJson(id: 'r1')],
              'nextCursor': 'c1',
            },
          }),
        )
        ..reviewsPage = CursorPage(
          items: [
            Review.fromJson({...reviewJson(id: 'r2'), 'comment': 'Second one'}),
          ],
        );
      await open(tester, repo: repo);
      await tester.ensureVisible(find.byKey(const Key('reviews-more')));

      expect(find.text('Great plan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reviews-more')));
      await tester.pumpAndSettle();

      expect(repo.reviewCursors, ['c1']);
      expect(find.text('Second one'), findsOneWidget);
      expect(find.byKey(const Key('reviews-more')), findsNothing);
    });

    testWidgets('shows an empty message without reviews', (tester) async {
      await open(
        tester,
        repo: FakeDrawingsRepository(
          detail: DrawingDetail.fromJson({
            ...detailJson(),
            'reviews': {'items': <Object>[], 'nextCursor': null},
          }),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('reviews-empty')));

      expect(find.byKey(const Key('reviews-empty')), findsOneWidget);
    });
  });
}
