import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/basket/domain/basket_repositories.dart';
import 'package:sketch_square/features/basket/domain/cart.dart';
import 'package:sketch_square/features/basket/domain/checkout_models.dart';
import 'package:sketch_square/features/basket/domain/payment_gateway.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';

import '../../helpers/commerce_fixtures.dart';

class FakeCartRepository implements CartRepository {
  FakeCartRepository({List<DrawingSummary>? items}) : items = items ?? [];

  List<DrawingSummary> items;
  ApiException? error;
  int getCalls = 0;

  Cart get _cart => Cart(
    items: List.of(items),
    totalPaise: items.fold(0, (s, d) => s + d.pricePaise),
  );

  void _check() {
    if (error != null) throw error!;
  }

  @override
  Future<Cart> getCart() async {
    getCalls++;
    _check();
    return _cart;
  }

  @override
  Future<Cart> add(String drawingId) async {
    _check();
    if (!items.any((d) => d.id == drawingId)) {
      items.add(fakeDrawing(id: drawingId));
    }
    return _cart;
  }

  @override
  Future<Cart> remove(String drawingId) async {
    _check();
    items.removeWhere((d) => d.id == drawingId);
    return _cart;
  }
}

class FakeCheckoutRepository implements CheckoutRepository {
  CheckoutOrder order = const CheckoutOrder(
    orderId: 'order_stub_1',
    razorpayKeyId: 'stub',
    amountPaise: 150000,
    purchaseIds: ['p1'],
  );
  OrderStatus stubCompleteStatus = OrderStatus.paid;
  OrderStatus verifyStatus = OrderStatus.paid;
  OrderStatus statusResult = OrderStatus.paid;
  ApiException? createError;
  ApiException? verifyError;
  ApiException? statusError;
  final calls = <String>[];
  PaymentConfirmation? lastConfirmation;

  @override
  Future<CheckoutOrder> createOrder() async {
    calls.add('createOrder');
    if (createError != null) throw createError!;
    return order;
  }

  @override
  Future<OrderStatus> verify(PaymentConfirmation confirmation) async {
    calls.add('verify');
    lastConfirmation = confirmation;
    if (verifyError != null) throw verifyError!;
    return verifyStatus;
  }

  @override
  Future<OrderStatus> stubComplete(String orderId) async {
    calls.add('stubComplete');
    return stubCompleteStatus;
  }

  @override
  Future<OrderStatus> status(String orderId) async {
    calls.add('status');
    if (statusError != null) throw statusError!;
    return statusResult;
  }
}

class FakePaymentGateway implements PaymentGateway {
  GatewayResult result = const GatewayCancelled();
  int calls = 0;
  CheckoutOrder? lastOrder;
  PaymentPrefill? lastPrefill;

  @override
  Future<GatewayResult> pay(
    CheckoutOrder order, {
    PaymentPrefill? prefill,
  }) async {
    calls++;
    lastOrder = order;
    lastPrefill = prefill;
    return result;
  }
}

const networkError = ApiException(
  code: ApiErrorCodes.network,
  message: 'Unable to reach the server.',
);
