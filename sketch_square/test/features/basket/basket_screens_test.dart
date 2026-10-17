import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/basket/data/basket_providers.dart';
import 'package:sketch_square/features/basket/data/pending_checkout_store.dart';
import 'package:sketch_square/features/basket/domain/checkout_models.dart';

import '../../helpers/commerce_fixtures.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

void main() {
  late FakeCartRepository cart;
  late FakeCheckoutRepository checkout;
  late FakePaymentGateway gateway;

  setUp(() {
    cart = FakeCartRepository(
      items: [
        fakeDrawing(id: 'd1'),
        fakeDrawing(id: 'd2', title: 'Duplex', pricePaise: 50050),
      ],
    );
    checkout = FakeCheckoutRepository();
    gateway = FakePaymentGateway();
  });

  Future<void> openBasket(WidgetTester tester) => pumpApp(
    tester,
    overrides: [
      cartRepositoryProvider.overrideWithValue(cart),
      checkoutRepositoryProvider.overrideWithValue(checkout),
      paymentGatewayProvider.overrideWithValue(gateway),
      pendingCheckoutStoreProvider.overrideWithValue(
        InMemoryPendingCheckoutStore(),
      ),
    ],
  ).then((_) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Basket'),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('basket lists items with the total and removes an item', (
    tester,
  ) async {
    await openBasket(tester);

    expect(find.text('Modern Villa'), findsOneWidget);
    expect(find.text('Duplex'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('basket-total'))).data,
      '₹2,000.50',
    );

    await tester.tap(find.byTooltip('Remove Modern Villa'));
    await tester.pumpAndSettle();

    expect(find.text('Modern Villa'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('basket-total'))).data,
      '₹500.50',
    );
  });

  testWidgets('empty basket shows the empty state without a checkout bar', (
    tester,
  ) async {
    cart.items.clear();
    await openBasket(tester);

    expect(find.text('Your basket is empty'), findsOneWidget);
    expect(find.text('Checkout'), findsNothing);
  });

  testWidgets('load failure shows retry that recovers', (tester) async {
    cart.error = networkError;
    await openBasket(tester);
    expect(find.text('Retry'), findsOneWidget);

    cart.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Modern Villa'), findsOneWidget);
  });

  testWidgets('stub checkout: Checkout -> Pay -> success result', (
    tester,
  ) async {
    await openBasket(tester);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-total')), findsOneWidget);
    expect(find.textContaining('non-exclusive licence'), findsOneWidget);

    await tester.tap(find.text('Pay ₹2,000.50'));
    await tester.pumpAndSettle();

    expect(find.text('Payment successful'), findsOneWidget);
    expect(checkout.calls, ['createOrder', 'stubComplete']);
    expect(gateway.calls, 0);
  });

  testWidgets('checkout licence notice links to the terms', (tester) async {
    await openBasket(tester);
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checkout-terms-link')));
    await tester.pumpAndSettle();
    expect(inAppBar('Terms of Service'), findsOneWidget);
  });

  testWidgets('a failed payment shows the failure screen with retry', (
    tester,
  ) async {
    checkout.stubCompleteStatus = OrderStatus.failed;
    await openBasket(tester);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₹2,000.50'));
    await tester.pumpAndSettle();

    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
