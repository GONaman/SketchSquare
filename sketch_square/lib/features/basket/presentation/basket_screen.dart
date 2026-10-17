import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../upload/domain/money.dart';
import '../../../core/format/plot_size.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/drawing_thumbnail.dart';
import '../../../core/widgets/error_retry.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';

class BasketScreen extends ConsumerStatefulWidget {
  const BasketScreen({super.key});

  @override
  ConsumerState<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends ConsumerState<BasketScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(checkoutControllerProvider.notifier).resumePending(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _wasActive = true;

  // Inactive tab branches have tickers disabled; refresh the basket (it may
  // have changed from a drawing page) when this tab becomes visible again.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.of(context);
    if (active && !_wasActive) {
      Future.microtask(
        () => ref.read(cartControllerProvider.notifier).refresh(),
      );
    }
    _wasActive = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(checkoutControllerProvider.notifier).resumePending();
    }
  }

  Future<void> _remove(DrawingSummary item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cartControllerProvider.notifier).remove(item.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(toApiException(e).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final checkout = ref.watch(checkoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Basket')),
      body: Column(
        children: [
          if (checkout is CheckoutPending) const _PendingBanner(),
          Expanded(
            child: cart.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => ErrorRetry(
                    message: toApiException(e).message,
                    onRetry: () => ref.invalidate(cartControllerProvider),
                  ),
              data:
                  (data) =>
                      data.isEmpty
                          ? const BlueprintEmptyState(
                            icon: Icons.shopping_basket_outlined,
                            title: 'Your basket is empty',
                            message: 'Drawings you add will appear here.',
                          )
                          : RefreshIndicator(
                            onRefresh:
                                ref
                                    .read(cartControllerProvider.notifier)
                                    .refresh,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: data.items.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder:
                                  (_, i) => CartItemTile(
                                    item: data.items[i],
                                    onRemove: () => _remove(data.items[i]),
                                  ),
                            ),
                          ),
            ),
          ),
          if (cart.valueOrNull case final Cart c when !c.isEmpty)
            _CheckoutBar(cart: c),
        ],
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item, required this.onRemove});

  final DrawingSummary item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrawingThumbnail(url: item.previewUrl, size: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${formatPlotSize(item.plotLengthFt, item.plotBreadthFt)} · ${item.city}',
                style: muted,
              ),
              Text('by ${item.architect.fullName}', style: muted),
              const SizedBox(height: 4),
              Text(
                formatPaise(item.pricePaise),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove ${item.title}',
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${cart.itemCount} ${cart.itemCount == 1 ? 'drawing' : 'drawings'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      formatPaise(cart.totalPaise),
                      key: const Key('basket-total'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push(AppRoutes.basketCheckout),
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBanner extends ConsumerWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialBanner(
      leading: const Icon(Icons.hourglass_top),
      content: const Text('Confirming your last payment…'),
      actions: [
        TextButton(
          onPressed:
              () =>
                  ref.read(checkoutControllerProvider.notifier).resumePending(),
          child: const Text('Check status'),
        ),
      ],
    );
  }
}
