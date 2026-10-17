import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/error_retry.dart';
import '../../architects/domain/architect_summary.dart';
import '../../architects/presentation/architect_profile_screen.dart';
import '../../basket/presentation/cart_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../data/drawings_providers.dart';
import '../domain/drawing_detail.dart';
import '../domain/sheet.dart';
import 'discovery_paths.dart';
import 'drawing_gallery.dart';
import 'drawing_purchase_bar.dart';
import 'drawing_reviews_section.dart';
import 'formatters.dart';

class DrawingDetailScreen extends ConsumerStatefulWidget {
  const DrawingDetailScreen({
    super.key,
    required this.drawingId,
    required this.paths,
  });

  final String drawingId;
  final DiscoveryPaths paths;

  @override
  ConsumerState<DrawingDetailScreen> createState() =>
      _DrawingDetailScreenState();
}

class _DrawingDetailScreenState extends ConsumerState<DrawingDetailScreen> {
  bool _busy = false;
  bool _inCart = false;
  // Null until the user toggles it; then it overrides the server's flag.
  bool? _favorite;

  void _toast(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<bool> _addToBasket() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(drawingActionsRepositoryProvider)
          .addToCart(widget.drawingId);
      ref.invalidate(cartControllerProvider);
      if (mounted) setState(() => _inCart = true);
      return true;
    } catch (e) {
      if (mounted) _toast(toApiException(e).message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addAndStay() async {
    if (!await _addToBasket() || !mounted) return;
    _toast(
      'Added to basket',
      action: SnackBarAction(label: 'View', onPressed: _openBasket),
    );
  }

  Future<void> _buyNow() async {
    if (await _addToBasket() && mounted) _openBasket();
  }

  void _openBasket() => context.go(AppRoutes.basket);

  Future<void> _toggleFavorite(bool current) async {
    final next = !current;
    setState(() => _favorite = next);
    try {
      await ref
          .read(drawingActionsRepositoryProvider)
          .setFavorite(widget.drawingId, favorite: next);
      ref.invalidate(favoritesControllerProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorite = current);
      _toast(toApiException(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(drawingDetailProvider(widget.drawingId));
    return detail.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: const Text('Drawing')),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Drawing')),
            body: ErrorRetry(
              message: toApiException(e).message,
              onRetry:
                  () => ref.invalidate(drawingDetailProvider(widget.drawingId)),
            ),
          ),
      data: _buildLoaded,
    );
  }

  Widget _buildLoaded(DrawingDetail d) {
    final favorite = _favorite ?? d.viewer.isFavorite;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.summary.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (!d.viewer.isOwner)
            IconButton(
              key: const Key('favorite-button'),
              tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
              onPressed: () => _toggleFavorite(favorite),
              icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh:
            () => ref.refresh(drawingDetailProvider(widget.drawingId).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            DrawingGallery(urls: d.previewUrls),
            _Overview(detail: d),
            _SheetsSection(detail: d),
            _ArchitectCard(
              architect: d.summary.architect,
              onTap:
                  () => context.push(
                    widget.paths.architect(d.summary.architect.id),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DrawingReviewsSection(
                    drawingId: d.summary.id,
                    initial: d.reviews,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PurchaseBar(
        detail: d,
        inCart: _inCart,
        busy: _busy,
        onDownload: () => _toast('Downloads are coming soon.'),
        onAddToBasket: _addAndStay,
        onBuyNow: _buyNow,
        onViewBasket: _openBasket,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.detail});

  final DrawingDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = detail.summary;
    final facts = <(IconData, String)>[
      (Icons.straighten, formatPlotSize(s)),
      (Icons.square_foot, formatArea(s.plotAreaSqft)),
      (
        Icons.layers_outlined,
        '${s.floors} ${s.floors == 1 ? 'floor' : 'floors'}',
      ),
      if (s.facing != null) (Icons.explore_outlined, '${s.facing} facing'),
      (Icons.place_outlined, s.city),
      (Icons.category_outlined, s.category.name),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title,
            key: const Key('detail-title'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                s.isFree ? 'Free' : formatPaise(s.pricePaise),
                key: const Key('detail-price'),
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              if (s.ratingCount > 0) ...[
                const Icon(Icons.star_rounded, size: 20),
                const SizedBox(width: 2),
                Text(
                  '${formatRating(s.avgRating)} (${s.ratingCount})',
                  style: theme.textTheme.bodyMedium,
                ),
              ] else
                Text('No ratings yet', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label) in facts)
                Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('About this drawing', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(detail.description, key: const Key('detail-description')),
          ],
        ],
      ),
    );
  }
}

class _SheetsSection extends StatelessWidget {
  const _SheetsSection({required this.detail});

  final DrawingDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.sheets.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final v = detail.viewer;
    final unlocked = v.isOwner || v.isPurchased || v.canDownload;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sheets (${detail.sheets.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final sheet in detail.sheets)
            ListTile(
              key: Key('sheet-${sheet.id}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                unlocked ? Icons.lock_open : Icons.lock_outline,
                key: Key(
                  unlocked
                      ? 'sheet-open-${sheet.id}'
                      : 'sheet-locked-${sheet.id}',
                ),
              ),
              title: Text(sheetTypeLabel(sheet.type)),
              subtitle: Text(
                unlocked
                    ? sheet.fileName
                    : (sheet.isPreview
                        ? 'Watermarked preview'
                        : 'Included with purchase'),
              ),
            ),
        ],
      ),
    );
  }
}

String sheetTypeLabel(SheetType type) {
  final n = type.name;
  return '${n[0].toUpperCase()}${n.substring(1)} sheet';
}

class _ArchitectCard extends StatelessWidget {
  const _ArchitectCard({required this.architect, required this.onTap});

  final ArchitectSummary architect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          key: const Key('architect-card'),
          onTap: onTap,
          leading: ArchitectAvatar(architect: architect),
          title: Text(architect.fullName),
          subtitle: Text(
            architect.ratingCount > 0
                ? '${architect.city} · ★ ${formatRating(architect.architectRating)}'
                : architect.city,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
