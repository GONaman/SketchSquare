import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/plot_size.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
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
    final scheme = theme.colorScheme;
    final cartAsync = ref.watch(cartControllerProvider);
    final cart = cartAsync.valueOrNull;
    final state = ref.watch(checkoutControllerProvider);
    final processing = state is CheckoutProcessing;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body:
          cart == null
              ? (cartAsync.hasError
                  ? ErrorState(
                    message: toApiException(cartAsync.error!).message,
                    onRetry: () => ref.invalidate(cartControllerProvider),
                  )
                  : const ListRowSkeleton(count: 3))
              : cart.isEmpty
              ? const EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'Your basket is empty',
                message: 'Add a drawing to check out.',
                compact: true,
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      children: [
                        AppCard(
                          style: AppCardStyle.outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order summary',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              for (final item in cart.items)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      DrawingThumbnail(
                                        url: item.previewUrl,
                                        size: 52,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            Text(
                                              formatPlotSize(
                                                item.plotLengthFt,
                                                item.plotBreadthFt,
                                              ),
                                              style:
                                                  theme.textTheme.bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            scheme
                                                                .onSurfaceVariant,
                                                      )
                                                      .tabular,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      PriceText(
                                        paise: item.pricePaise,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              const Divider(height: AppSpacing.md),
                              const SizedBox(height: AppSpacing.xs),
                              SummaryRow(
                                label: 'Total',
                                value: formatPaise(cart.totalPaise),
                                valueKey: const Key('checkout-total'),
                                emphasis: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          style: AppCardStyle.tonal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_outlined,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Usage rights',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Licence: you receive a non-exclusive licence to use '
                                'these drawings for your own projects. Resale or '
                                're-upload is not permitted.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                key: const Key('checkout-terms-link'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => context.push(AppRoutes.terms),
                                child: const Text('Read the Terms of Service'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant),
                      ),
                      boxShadow: AppElevation.level2(scheme.brightness),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.gutter),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state case CheckoutProcessing(:final step))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  stepLabel(step),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            PrimaryButton(
                              label: 'Pay ${formatPaise(cart.totalPaise)}',
                              icon: Icons.lock_outline_rounded,
                              accent: true,
                              loading: processing,
                              onPressed:
                                  () =>
                                      ref
                                          .read(
                                            checkoutControllerProvider.notifier,
                                          )
                                          .start(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
