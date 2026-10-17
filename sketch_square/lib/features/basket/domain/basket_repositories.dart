import 'cart.dart';
import 'checkout_models.dart';

/// `/cart` endpoints. Implementations throw `ApiException` (see `toApiException`).
abstract interface class CartRepository {
  Future<Cart> getCart();
  Future<Cart> add(String drawingId);
  Future<Cart> remove(String drawingId);
}

/// `/checkout` endpoints.
abstract interface class CheckoutRepository {
  Future<CheckoutOrder> createOrder();
  Future<OrderStatus> verify(PaymentConfirmation confirmation);

  /// Stub mode only: simulates the captured-payment webhook.
  Future<OrderStatus> stubComplete(String orderId);
  Future<OrderStatus> status(String orderId);
}
