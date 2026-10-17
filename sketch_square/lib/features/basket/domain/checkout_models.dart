import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_models.freezed.dart';
part 'checkout_models.g.dart';

enum OrderStatus {
  created,
  paid,
  failed;

  /// Parses the `status` field of checkout responses; unknown values are
  /// treated as still [created].
  static OrderStatus fromApi(Object? raw) => switch (raw) {
    'PAID' => paid,
    'FAILED' => failed,
    _ => created,
  };
}

/// `POST /checkout` response. `razorpayKeyId == "stub"` means stub mode.
@freezed
abstract class CheckoutOrder with _$CheckoutOrder {
  const CheckoutOrder._();

  const factory CheckoutOrder({
    required String orderId,
    required String razorpayKeyId,
    required int amountPaise,
    @Default('INR') String currency,
    @Default([]) List<String> purchaseIds,
  }) = _CheckoutOrder;

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) =>
      _$CheckoutOrderFromJson(json);

  static const stubKeyId = 'stub';

  bool get isStub => razorpayKeyId == stubKeyId;
}

/// Payload of `POST /checkout/verify`, taken from Razorpay's success callback.
class PaymentConfirmation {
  const PaymentConfirmation({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() => {
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpaySignature': razorpaySignature,
  };
}
