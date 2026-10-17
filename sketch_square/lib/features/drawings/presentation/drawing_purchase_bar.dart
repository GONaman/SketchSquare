import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../domain/drawing_detail.dart';

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
    this.inline = false,
    required this.onDownload,
    required this.onAddToBasket,
    required this.onBuyNow,
    required this.onViewBasket,
  });

  final DrawingDetail detail;
  final bool inCart;
  final bool busy;

  /// Renders as a padded block inside a card instead of the sticky bar.
  final bool inline;
  final VoidCallback onDownload;
  final VoidCallback onAddToBasket;
  final VoidCallback onBuyNow;
  final VoidCallback onViewBasket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = detail.summary;
    final action = purchaseActionFor(detail, inCart: inCart);
    final left = detail.viewer.freeDownloadsRemaining;

    final Widget content = switch (action) {
      PurchaseAction.owner => const _Info(
        key: Key('bar-owner'),
        icon: Icons.verified_user_outlined,
        text: 'This is your drawing',
      ),
      PurchaseAction.download => PrimaryButton(
        key: const Key('bar-download'),
        onPressed: onDownload,
        icon: Icons.download_rounded,
        label:
            summary.isFree && left != null
                ? 'Download free ($left left)'
                : 'Download',
      ),
      PurchaseAction.freeLimitReached => const _Info(
        key: Key('bar-free-limit'),
        icon: Icons.lock_outline,
        text: 'Free download limit reached',
      ),
      PurchaseAction.inBasket => PrimaryButton(
        key: const Key('bar-in-basket'),
        onPressed: onViewBasket,
        icon: Icons.shopping_basket_outlined,
        label: 'In basket · View basket',
      ),
      PurchaseAction.buy => Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              PriceText(
                key: const Key('bar-price'),
                paise: summary.pricePaise,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton.outlined(
            key: const Key('bar-add-to-basket'),
            tooltip: 'Add to basket',
            onPressed: busy ? null : onAddToBasket,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(52),
              side: BorderSide(color: scheme.outline),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: PrimaryButton(
              key: const Key('bar-buy-now'),
              accent: true,
              onPressed: busy ? null : onBuyNow,
              label: 'Buy now',
            ),
          ),
        ],
      ),
    };

    if (inline) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: content,
      );
    }

    return Material(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              child: content,
            ),
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
        const SizedBox(width: AppSpacing.sm),
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
