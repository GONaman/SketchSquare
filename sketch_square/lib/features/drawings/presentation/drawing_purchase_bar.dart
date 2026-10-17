import 'package:flutter/material.dart';

import '../domain/drawing_detail.dart';
import 'formatters.dart';

/// What the sticky bottom bar of the detail screen offers.
enum PurchaseAction { owner, download, freeLimitReached, inBasket, buy }

/// Decides the bar state from the server's `viewer` flags. [inCart] lets the
/// screen reflect an add-to-basket it just did before the detail refetches.
PurchaseAction purchaseActionFor(DrawingDetail d, {bool inCart = false}) {
  final v = d.viewer;
  if (v.isOwner) return PurchaseAction.owner;
  if (v.canDownload) return PurchaseAction.download;
  if (d.summary.isFree) return PurchaseAction.freeLimitReached;
  if (v.inCart || inCart) return PurchaseAction.inBasket;
  return PurchaseAction.buy;
}

class PurchaseBar extends StatelessWidget {
  const PurchaseBar({
    super.key,
    required this.detail,
    required this.inCart,
    required this.busy,
    required this.onDownload,
    required this.onAddToBasket,
    required this.onBuyNow,
    required this.onViewBasket,
  });

  final DrawingDetail detail;
  final bool inCart;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onAddToBasket;
  final VoidCallback onBuyNow;
  final VoidCallback onViewBasket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    final action = purchaseActionFor(detail, inCart: inCart);
    final left = detail.viewer.freeDownloadsRemaining;

    final Widget buttons = switch (action) {
      PurchaseAction.owner => const _Info(
        key: Key('bar-owner'),
        icon: Icons.verified_user_outlined,
        text: 'This is your drawing',
      ),
      PurchaseAction.download => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('bar-download'),
          onPressed: onDownload,
          icon: const Icon(Icons.download),
          label: Text(
            summary.isFree && left != null
                ? 'Download free ($left left)'
                : 'Download',
          ),
        ),
      ),
      PurchaseAction.freeLimitReached => const _Info(
        key: Key('bar-free-limit'),
        icon: Icons.lock_outline,
        text: 'Free download limit reached',
      ),
      PurchaseAction.inBasket => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('bar-in-basket'),
          onPressed: onViewBasket,
          icon: const Icon(Icons.shopping_basket),
          label: const Text('In basket · View basket'),
        ),
      ),
      PurchaseAction.buy => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('bar-add-to-basket'),
              onPressed: busy ? null : onAddToBasket,
              child: const Text('Add to basket'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const Key('bar-buy-now'),
              onPressed: busy ? null : onBuyNow,
              child: const Text('Buy now'),
            ),
          ),
        ],
      ),
    };

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (action == PurchaseAction.buy) ...[
                Text(
                  summary.isFree ? 'Free' : formatPaise(summary.pricePaise),
                  key: const Key('bar-price'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(child: buttons),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
