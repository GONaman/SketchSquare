import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../data/basket_providers.dart';
import '../domain/checkout_models.dart';
import '../domain/payment_gateway.dart';
import '../../purchases/presentation/purchases_controller.dart';
import 'cart_controller.dart';

part 'checkout_controller.g.dart';

enum CheckoutStep { creatingOrder, awaitingPayment, verifying }

sealed class CheckoutState {
  const CheckoutState();
}

class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing(this.step);
  final CheckoutStep step;
}

class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess({required this.orderId, this.amountPaise});
  final String orderId;
  final int? amountPaise;
}

/// [cancelled] means the user dismissed the payment sheet (not an error).
class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(this.message, {this.orderId, this.cancelled = false});
  final String message;
  final String? orderId;
  final bool cancelled;
}

/// Payment was submitted but the server hasn't confirmed it yet.
class CheckoutPending extends CheckoutState {
  const CheckoutPending(this.orderId, {this.amountPaise});
  final String orderId;
  final int? amountPaise;
}

/// Drives basket -> order -> payment -> confirmation. In stub mode
/// (`razorpayKeyId == "stub"`) the payment sheet is skipped and the backend's
/// `/checkout/stub-complete` simulates the captured-payment webhook.
@Riverpod(keepAlive: true)
class CheckoutController extends _$CheckoutController {
  @override
  CheckoutState build() => const CheckoutIdle();

  bool get _busy => state is CheckoutProcessing;

  Future<void> start() async {
    if (_busy) return;
    state = const CheckoutProcessing(CheckoutStep.creatingOrder);
    final repo = ref.read(checkoutRepositoryProvider);
    CheckoutOrder? order;
    try {
      order = await repo.createOrder();
      await ref.read(pendingCheckoutStoreProvider).write(order.orderId);

      if (order.isStub) {
        state = const CheckoutProcessing(CheckoutStep.verifying);
        await _settle(order, await repo.stubComplete(order.orderId));
        return;
      }

      state = const CheckoutProcessing(CheckoutStep.awaitingPayment);
      final result = await ref
          .read(paymentGatewayProvider)
          .pay(order, prefill: _prefill());
      switch (result) {
        case GatewayCancelled():
          await ref.read(pendingCheckoutStoreProvider).clear();
          state = CheckoutFailure(
            'Payment cancelled.',
            orderId: order.orderId,
            cancelled: true,
          );
        case GatewayFailure(:final message):
          await ref.read(pendingCheckoutStoreProvider).clear();
          state = CheckoutFailure(message, orderId: order.orderId);
        case GatewaySuccess(:final confirmation):
          state = const CheckoutProcessing(CheckoutStep.verifying);
          await _verify(order, confirmation);
      }
    } catch (e) {
      final error = toApiException(e);
      state = CheckoutFailure(error.message, orderId: order?.orderId);
    }
  }

  Future<void> _verify(CheckoutOrder order, PaymentConfirmation c) async {
    final repo = ref.read(checkoutRepositoryProvider);
    try {
      await _settle(order, await repo.verify(c));
    } catch (_) {
      // The payment went through on Razorpay's side; fall back to polling the
      // order status (webhook is the source of truth).
      try {
        await _settle(order, await repo.status(order.orderId));
      } catch (_) {
        state = CheckoutPending(order.orderId, amountPaise: order.amountPaise);
      }
    }
  }

  Future<void> _settle(CheckoutOrder order, OrderStatus status) =>
      _applyStatus(order.orderId, status, order.amountPaise);

  Future<void> _applyStatus(
    String orderId,
    OrderStatus status,
    int? amountPaise,
  ) async {
    switch (status) {
      case OrderStatus.paid:
        await ref.read(pendingCheckoutStoreProvider).clear();
        ref.invalidate(cartControllerProvider);
        ref.invalidate(purchasesControllerProvider);
        state = CheckoutSuccess(orderId: orderId, amountPaise: amountPaise);
      case OrderStatus.failed:
        await ref.read(pendingCheckoutStoreProvider).clear();
        state = CheckoutFailure(
          'Payment failed. You have not been charged.',
          orderId: orderId,
        );
      case OrderStatus.created:
        state = CheckoutPending(orderId, amountPaise: amountPaise);
    }
  }

  /// Re-checks an order interrupted by an app kill / lost connection.
  /// No-op when nothing is pending. Call when the basket opens or the app resumes.
  Future<void> resumePending() async {
    if (_busy) return;
    final current = state;
    final orderId =
        current is CheckoutPending
            ? current.orderId
            : await ref.read(pendingCheckoutStoreProvider).read();
    if (orderId == null) return;
    try {
      await _applyStatus(
        orderId,
        await ref.read(checkoutRepositoryProvider).status(orderId),
        current is CheckoutPending ? current.amountPaise : null,
      );
    } catch (_) {
      state = CheckoutPending(orderId);
    }
  }

  void reset() => state = const CheckoutIdle();

  PaymentPrefill? _prefill() {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    return PaymentPrefill(
      name: user.fullName,
      email: user.email,
      contact: user.phone,
    );
  }
}
