import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../domain/checkout_models.dart';
import '../domain/payment_gateway.dart';

/// Opens the native Razorpay checkout. Not used in stub mode (see
/// `CheckoutController`), so it never needs real keys locally.
class RazorpayGateway implements PaymentGateway {
  RazorpayGateway({this.merchantName = 'SketchSquare'});

  final String merchantName;

  @override
  Future<GatewayResult> pay(
    CheckoutOrder order, {
    PaymentPrefill? prefill,
  }) async {
    final razorpay = Razorpay();
    final completer = Completer<GatewayResult>();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      final paymentId = r.paymentId;
      final signature = r.signature;
      if (completer.isCompleted) return;
      if (paymentId == null || signature == null) {
        completer.complete(
          const GatewayFailure('Payment could not be confirmed.'),
        );
        return;
      }
      completer.complete(
        GatewaySuccess(
          PaymentConfirmation(
            razorpayOrderId: r.orderId ?? order.orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          ),
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (completer.isCompleted) return;
      completer.complete(
        r.code == Razorpay.PAYMENT_CANCELLED
            ? const GatewayCancelled()
            : GatewayFailure(r.message ?? 'Payment failed. Please try again.'),
      );
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});

    try {
      razorpay.open({
        'key': order.razorpayKeyId,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': merchantName,
        'description': 'Architectural drawings',
        'prefill': {
          if (prefill?.name != null) 'name': prefill!.name,
          if (prefill?.email != null) 'email': prefill!.email,
          if (prefill?.contact != null) 'contact': prefill!.contact,
        },
      });
      return await completer.future;
    } catch (_) {
      return const GatewayFailure('Unable to open the payment sheet.');
    } finally {
      razorpay.clear();
    }
  }
}
