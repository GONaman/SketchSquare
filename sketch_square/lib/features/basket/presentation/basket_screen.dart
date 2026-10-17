import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
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
              loading: () => const ListRowSkeleton(count: 3),
              error:
                  (e, _) => ErrorState(
                    message: toApiException(e).message,
                    onRetry: () => ref.invalidate(cartControllerProvider),
                  ),
              data:
                  (data) =>
                      data.isEmpty
                          ? EmptyState(
                            icon: Icons.shopping_basket_outlined,
                            title: 'Your basket is empty',
                            message:
                                'Drawings you add will appear here, ready for '
                                'one-tap checkout.',
                            action: PrimaryButton(
                              label: 'Browse drawings',
                              icon: Icons.search_rounded,
                              expand: false,
                              onPressed: () => context.go(AppRoutes.home),
                            ),
                          )
                          : RefreshIndicator(
                            onRefresh:
                                ref
                                    .read(cartControllerProvider.notifier)
                                    .refresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter,
                                AppSpacing.sm,
                                AppSpacing.gutter,
                                AppSpacing.xl,
                              ),
                              children: [
                                for (final item in data.items)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: CartItemTile(
                                      item: item,
                                      onRemove: () => _remove(item),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                _PriceSummary(cart: data),
                              ],
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawingThumbnail(url: item.previewUrl, size: 88),
          const SizedBox(width: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.xs),
                PlotSizeBadge(
                  lengthFt: item.plotLengthFt,
                  breadthFt: item.plotBreadthFt,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.city} · by ${item.architect.fullName}',
                  style: muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                PriceText(
                  paise: item.pricePaise,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${item.title}',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noun = cart.itemCount == 1 ? 'drawing' : 'drawings';
    return AppCard(
      style: AppCardStyle.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price details', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SummaryRow(
            label: 'Subtotal (${cart.itemCount} $noun)',
            value: formatPaise(cart.totalPaise),
          ),
          SummaryRow(
            label: 'Delivery',
            value: 'Instant download',
            valueColor: AppSemanticColors.of(context).success,
          ),
          const Divider(height: AppSpacing.lg),
          SummaryRow(
            label: 'Total',
            value: formatPaise(cart.totalPaise),
            emphasis: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppSemanticColors.of(context).success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Secure payment · instant download · licence included',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: AppElevation.level2(scheme.brightness),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.itemCount} ${cart.itemCount == 1 ? 'drawing' : 'drawings'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatPaise(cart.totalPaise),
                    key: const Key('basket-total'),
                    style: theme.textTheme.titleLarge?.tabular,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: PrimaryButton(
                  label: 'Checkout',
                  accent: true,
                  onPressed: () => context.push(AppRoutes.basketCheckout),
                ),
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
    final theme = Theme.of(context);
    final sem = AppSemanticColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: sem.warningContainer,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: sem.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Confirming your last payment…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed:
                () =>
                    ref
                        .read(checkoutControllerProvider.notifier)
                        .resumePending(),
            child: const Text('Check status'),
          ),
        ],
      ),
    );
  }
}
