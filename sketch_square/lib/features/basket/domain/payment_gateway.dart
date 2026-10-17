import 'checkout_models.dart';

sealed class GatewayResult {
  const GatewayResult();
}

class GatewaySuccess extends GatewayResult {
  const GatewaySuccess(this.confirmation);
  final PaymentConfirmation confirmation;
}

class GatewayFailure extends GatewayResult {
  const GatewayFailure(this.message);
  final String message;
}

class GatewayCancelled extends GatewayResult {
  const GatewayCancelled();
}

/// Payer details used to prefill the Razorpay sheet.
class PaymentPrefill {
  const PaymentPrefill({this.name, this.email, this.contact});
  final String? name;
  final String? email;
  final String? contact;
}

/// Collects payment for an already-created [CheckoutOrder]. The Razorpay
/// implementation lives in `data/razorpay_gateway.dart`; tests use fakes.
abstract interface class PaymentGateway {
  Future<GatewayResult> pay(CheckoutOrder order, {PaymentPrefill? prefill});
}

/// Remembers an in-flight order so the app can re-check it after being killed
/// mid-payment.
abstract interface class PendingCheckoutStore {
  Future<String?> read();
  Future<void> write(String orderId);
  Future<void> clear();
}
