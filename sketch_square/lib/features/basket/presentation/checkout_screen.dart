import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../upload/domain/money.dart';
import '../../../core/format/plot_size.dart';
import '../../../core/router/routes.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';

/// Order summary + pay. Navigates to the order-result screen once the payment
/// settles (or is left pending); a dismissed payment sheet stays here.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  static String stepLabel(CheckoutStep step) => switch (step) {
    CheckoutStep.creatingOrder => 'Creating your order…',
    CheckoutStep.awaitingPayment => 'Waiting for payment…',
    CheckoutStep.verifying => 'Confirming payment…',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(checkoutControllerProvider, (_, next) {
      final controller = ref.read(checkoutControllerProvider.notifier);
      switch (next) {
        case CheckoutSuccess() || CheckoutPending():
          context.pushReplacement(AppRoutes.basketOrderResult);
        case CheckoutFailure(:final orderId, :final message, :final cancelled):
          if (orderId != null && !cancelled) {
            context.pushReplacement(AppRoutes.basketOrderResult);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            controller.reset();
          }
        default:
      }
    });

    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider).valueOrNull;
    final state = ref.watch(checkoutControllerProvider);
    final processing = state is CheckoutProcessing;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body:
          cart == null || cart.isEmpty
              ? const Center(child: Text('Your basket is empty.'))
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Order summary',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final item in cart.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title),
                                      Text(
                                        formatPlotSize(
                                          item.plotLengthFt,
                                          item.plotBreadthFt,
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(formatPaise(item.pricePaise)),
                              ],
                            ),
                          ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Text('Total', style: theme.textTheme.titleMedium),
                            const Spacer(),
                            Text(
                              formatPaise(cart.totalPaise),
                              key: const Key('checkout-total'),
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Licence: you receive a non-exclusive licence to use '
                          'these drawings for your own projects. Resale or '
                          're-upload is not permitted.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state case CheckoutProcessing(:final step))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(stepLabel(step)),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  processing
                                      ? null
                                      : () =>
                                          ref
                                              .read(
                                                checkoutControllerProvider
                                                    .notifier,
                                              )
                                              .start(),
                              child:
                                  processing
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        'Pay ${formatPaise(cart.totalPaise)}',
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
