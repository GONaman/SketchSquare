import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../upload/domain/money.dart';
import '../../../core/router/routes.dart';
import 'checkout_controller.dart';

/// Result of the last checkout: success, failure, or "still confirming".
class OrderResultScreen extends ConsumerWidget {
  const OrderResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final theme = Theme.of(context);

    void backToBasket() {
      controller.reset();
      context.go(AppRoutes.basket);
    }

    final (icon, color, title, message, actions) = switch (state) {
      CheckoutSuccess(:final amountPaise) => (
        Icons.check_circle_outline,
        theme.colorScheme.primary,
        'Payment successful',
        amountPaise == null
            ? 'Your drawings are ready to download.'
            : '${formatPaise(amountPaise)} paid. Your drawings are ready to download.',
        <Widget>[
          FilledButton(
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.purchases);
            },
            child: const Text('View my purchases'),
          ),
          TextButton(
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.home);
            },
            child: const Text('Continue browsing'),
          ),
        ],
      ),
      CheckoutPending() => (
        Icons.hourglass_top,
        theme.colorScheme.tertiary,
        'Confirming payment',
        'We have not received confirmation yet. If money was deducted, your '
            'drawings will appear in My purchases shortly.',
        <Widget>[
          FilledButton(
            onPressed: controller.resumePending,
            child: const Text('Check status'),
          ),
          TextButton(
            onPressed: backToBasket,
            child: const Text('Back to basket'),
          ),
        ],
      ),
      CheckoutFailure(:final message) => (
        Icons.error_outline,
        theme.colorScheme.error,
        'Payment failed',
        message,
        <Widget>[
          FilledButton(
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.basketCheckout);
            },
            child: const Text('Try again'),
          ),
          TextButton(
            onPressed: backToBasket,
            child: const Text('Back to basket'),
          ),
        ],
      ),
      _ => (
        Icons.shopping_basket_outlined,
        theme.colorScheme.primary,
        'Nothing to show',
        'There is no recent order.',
        <Widget>[
          FilledButton(
            onPressed: backToBasket,
            child: const Text('Back to basket'),
          ),
        ],
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToBasket();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: color),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
