import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/basket/data/basket_providers.dart';
import 'package:sketch_square/features/basket/data/pending_checkout_store.dart';
import 'package:sketch_square/features/basket/domain/cart.dart';
import 'package:sketch_square/features/basket/domain/checkout_models.dart';
import 'package:sketch_square/features/basket/domain/payment_gateway.dart';
import 'package:sketch_square/features/basket/presentation/cart_controller.dart';
import 'package:sketch_square/features/basket/presentation/checkout_controller.dart';

import '../../helpers/commerce_fixtures.dart';
import 'fakes.dart';

class _Harness {
  _Harness() {
    cart = FakeCartRepository(
      items: [fakeDrawing(id: 'd1'), fakeDrawing(id: 'd2', pricePaise: 50050)],
    );
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cart),
        checkoutRepositoryProvider.overrideWithValue(checkout),
        paymentGatewayProvider.overrideWithValue(gateway),
        pendingCheckoutStoreProvider.overrideWithValue(store),
        currentUserProvider.overrideWithValue(stubUser),
      ],
    );
  }

  late final FakeCartRepository cart;
  final checkout = FakeCheckoutRepository();
  final gateway = FakePaymentGateway();
  final store = InMemoryPendingCheckoutStore();
  late final ProviderContainer container;

  CheckoutController get controller =>
      container.read(checkoutControllerProvider.notifier);
  CheckoutState get state => container.read(checkoutControllerProvider);
}

const _confirmation = PaymentConfirmation(
  razorpayOrderId: 'order_1',
  razorpayPaymentId: 'pay_1',
  razorpaySignature: 'sig_1',
);

const _liveOrder = CheckoutOrder(
  orderId: 'order_1',
  razorpayKeyId: 'rzp_test_x',
  amountPaise: 200050,
);

void main() {
  group('Cart model', () {
    test('computed total equals the server total and counts items', () {
      final cart = Cart(
        items: [fakeDrawing(id: 'a'), fakeDrawing(id: 'b', pricePaise: 50050)],
        totalPaise: 200050,
      );
      expect(cart.computedTotalPaise, 200050);
      expect(cart.computedTotalPaise, cart.totalPaise);
      expect(cart.itemCount, 2);
      expect(cart.contains('a'), isTrue);
      expect(cart.contains('z'), isFalse);
      expect(Cart.empty.isEmpty, isTrue);
      expect(Cart.empty.computedTotalPaise, 0);
    });
  });

  group('CartController', () {
    test(
      'loads, adds and removes items with totals from the repository',
      () async {
        final h = _Harness();
        addTearDown(h.container.dispose);

        var cart = await h.container.read(cartControllerProvider.future);
        expect(cart.totalPaise, 200050);
        expect(h.container.read(cartCountProvider), 2);

        await h.container.read(cartControllerProvider.notifier).add('d3');
        cart = h.container.read(cartControllerProvider).requireValue;
        expect(cart.itemCount, 3);
        expect(cart.totalPaise, 350050);

        await h.container.read(cartControllerProvider.notifier).remove('d1');
        cart = h.container.read(cartControllerProvider).requireValue;
        expect(cart.items.map((d) => d.id), ['d2', 'd3']);
        expect(cart.totalPaise, 200050);
      },
    );

    test('a failed mutation throws and keeps the previous cart', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await h.container.read(cartControllerProvider.future);

      h.cart.error = networkError;
      await expectLater(
        h.container.read(cartControllerProvider.notifier).remove('d1'),
        throwsA(networkError),
      );
      expect(
        h.container.read(cartControllerProvider).requireValue.itemCount,
        2,
      );
    });
  });

  group('CheckoutController (stub mode)', () {
    test(
      'skips the payment sheet, completes via stub-complete, clears pending',
      () async {
        final h = _Harness();
        addTearDown(h.container.dispose);

        await h.controller.start();

        expect(h.state, isA<CheckoutSuccess>());
        expect((h.state as CheckoutSuccess).orderId, 'order_stub_1');
        expect(h.checkout.calls, ['createOrder', 'stubComplete']);
        expect(h.gateway.calls, 0);
        expect(await h.store.read(), isNull);
      },
    );

    test(
      'stub order that is not paid becomes pending and stays remembered',
      () async {
        final h = _Harness();
        addTearDown(h.container.dispose);
        h.checkout.stubCompleteStatus = OrderStatus.created;

        await h.controller.start();

        expect(h.state, isA<CheckoutPending>());
        expect(await h.store.read(), 'order_stub_1');
      },
    );
  });

  group('CheckoutController (Razorpay)', () {
    _Harness live() {
      final h = _Harness();
      h.checkout.order = _liveOrder;
      return h;
    }

    test(
      'success -> verify -> paid; prefill comes from the signed-in user',
      () async {
        final h = live();
        addTearDown(h.container.dispose);
        h.gateway.result = const GatewaySuccess(_confirmation);

        await h.controller.start();

        expect(h.state, isA<CheckoutSuccess>());
        expect((h.state as CheckoutSuccess).amountPaise, 200050);
        expect(h.checkout.calls, ['createOrder', 'verify']);
        expect(h.checkout.lastConfirmation?.razorpayPaymentId, 'pay_1');
        expect(h.gateway.lastPrefill?.email, stubUser.email);
        expect(await h.store.read(), isNull);
      },
    );

    test('dismissing the sheet is a cancelled failure, not an error', () async {
      final h = live();
      addTearDown(h.container.dispose);
      h.gateway.result = const GatewayCancelled();

      await h.controller.start();

      final s = h.state as CheckoutFailure;
      expect(s.cancelled, isTrue);
      expect(h.checkout.calls, ['createOrder']);
      expect(await h.store.read(), isNull);
    });

    test('gateway failure surfaces the message with the order id', () async {
      final h = live();
      addTearDown(h.container.dispose);
      h.gateway.result = const GatewayFailure('Card declined');

      await h.controller.start();

      final s = h.state as CheckoutFailure;
      expect(s.message, 'Card declined');
      expect(s.cancelled, isFalse);
      expect(s.orderId, 'order_1');
    });

    test('verify says FAILED -> failure', () async {
      final h = live();
      addTearDown(h.container.dispose);
      h.gateway.result = const GatewaySuccess(_confirmation);
      h.checkout.verifyStatus = OrderStatus.failed;

      await h.controller.start();

      expect(h.state, isA<CheckoutFailure>());
    });

    test('verify call fails but status poll says PAID -> success', () async {
      final h = live();
      addTearDown(h.container.dispose);
      h.gateway.result = const GatewaySuccess(_confirmation);
      h.checkout.verifyError = networkError;

      await h.controller.start();

      expect(h.state, isA<CheckoutSuccess>());
      expect(h.checkout.calls, ['createOrder', 'verify', 'status']);
    });

    test(
      'verify and status both unreachable -> pending, order remembered',
      () async {
        final h = live();
        addTearDown(h.container.dispose);
        h.gateway.result = const GatewaySuccess(_confirmation);
        h.checkout.verifyError = networkError;
        h.checkout.statusError = networkError;

        await h.controller.start();

        expect(h.state, isA<CheckoutPending>());
        expect(await h.store.read(), 'order_1');
      },
    );

    test('createOrder error -> failure without an order id', () async {
      final h = live();
      addTearDown(h.container.dispose);
      h.checkout.createError = networkError;

      await h.controller.start();

      final s = h.state as CheckoutFailure;
      expect(s.orderId, isNull);
      expect(s.message, networkError.message);
      expect(h.gateway.calls, 0);
    });
  });

  group('resumePending', () {
    test('does nothing when no order is remembered', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      await h.controller.resumePending();

      expect(h.state, isA<CheckoutIdle>());
      expect(h.checkout.calls, isEmpty);
    });

    test(
      'a remembered order that was paid while the app was dead -> success',
      () async {
        final h = _Harness();
        addTearDown(h.container.dispose);
        await h.store.write('order_1');
        h.checkout.statusResult = OrderStatus.paid;

        await h.controller.resumePending();

        expect((h.state as CheckoutSuccess).orderId, 'order_1');
        expect(await h.store.read(), isNull);
      },
    );

    test('still CREATED -> pending; later FAILED -> failure', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await h.store.write('order_1');
      h.checkout.statusResult = OrderStatus.created;

      await h.controller.resumePending();
      expect(h.state, isA<CheckoutPending>());

      h.checkout.statusResult = OrderStatus.failed;
      await h.controller.resumePending();
      expect(h.state, isA<CheckoutFailure>());
      expect(await h.store.read(), isNull);
    });

    test('network error keeps it pending', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await h.store.write('order_1');
      h.checkout.statusError = networkError;

      await h.controller.resumePending();

      expect(h.state, isA<CheckoutPending>());
      expect(await h.store.read(), 'order_1');
    });
  });
}
