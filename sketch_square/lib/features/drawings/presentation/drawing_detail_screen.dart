import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../architects/domain/architect_summary.dart';
import '../../basket/presentation/cart_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../interest/presentation/interest_button.dart';
import '../data/drawings_providers.dart';
import '../domain/drawing_detail.dart';
import '../domain/drawing_summary.dart';
import '../domain/sheet.dart';
import 'discovery_paths.dart';
import 'drawing_card.dart' show drawingHeroTag;
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
      loading: () => const _DetailSkeleton(),
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
    final scheme = Theme.of(context).colorScheme;
    final overlay = IconButton.styleFrom(
      backgroundColor: scheme.surface.withValues(alpha: 0.88),
      foregroundColor: scheme.onSurface,
      minimumSize: const Size.square(44),
    );
    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: _headerHeight,
        onRefresh:
            () => ref.refresh(drawingDetailProvider(widget.drawingId).future),
        child: ContentFrame(
          maxWidth: _detailMaxWidth,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _headerHeight,
                backgroundColor: scheme.surface,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                leadingWidth: 60,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Center(child: BackButton(style: overlay)),
                ),
                actions: [
                  if (!d.viewer.isOwner)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: IconButton(
                        key: const Key('favorite-button'),
                        tooltip:
                            favorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                        onPressed: () => _toggleFavorite(favorite),
                        style: overlay,
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite ? scheme.error : null,
                        ),
                      ),
                    ),
                ],
                flexibleSpace: _GalleryHeader(
                  title: d.summary.title,
                  urls: d.previewUrls,
                  heroTag: drawingHeroTag(context, d.summary.id),
                ),
              ),
              SliverToBoxAdapter(child: _TitleBlock(detail: d)),
              SliverToBoxAdapter(child: _SpecGrid(summary: d.summary)),
              if (d.description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'About this drawing'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        child: Text(
                          d.description,
                          key: const Key('detail-description'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!d.viewer.isOwner &&
                  !d.summary.isFree &&
                  !d.viewer.isPurchased)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: InterestButton(
                      key: ValueKey('interest-${d.summary.id}'),
                      drawingId: d.summary.id,
                      initial: d.viewer.isInterested,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: _SheetsSection(detail: d)),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Architect'),
                    _ArchitectCard(
                      architect: d.summary.architect,
                      onTap:
                          () => context.push(
                            widget.paths.architect(d.summary.architect.id),
                          ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Reviews'),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      child: DrawingReviewsSection(
                        drawingId: d.summary.id,
                        initial: d.reviews,
                        avgRating:
                            d.summary.ratingCount > 0
                                ? d.summary.avgRating
                                : null,
                        ratingCount:
                            d.summary.ratingCount > 0
                                ? d.summary.ratingCount
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (!d.viewer.isOwner)
                const SliverToBoxAdapter(child: _LicenceNote()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
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

const _headerHeight = 320.0;
const _detailMaxWidth = 960.0;

/// Gallery that fills the expanding app bar and fades into a title as the
/// header collapses.
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.title,
    required this.urls,
    required this.heroTag,
  });

  final String title;
  final List<String> urls;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final min = kToolbarHeight + top;
    return LayoutBuilder(
      builder: (context, c) {
        final t = ((c.maxHeight - min) / (_headerHeight - kToolbarHeight))
            .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: t,
              child: DrawingGallery(urls: urls, height: null, heroTag: heroTag),
            ),
            if (t < 0.5)
              Positioned(
                left: 72,
                right: 72,
                top: top,
                height: kToolbarHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: 1 - t * 2,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drawing')),
      body: ContentFrame(
        maxWidth: _detailMaxWidth,
        child: const Shimmer(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 260, radius: 0),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 90, height: 24),
                      SizedBox(height: AppSpacing.md),
                      ShimmerBox(height: 28),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 180, height: 28),
                      SizedBox(height: AppSpacing.lg),
                      ShimmerBox(width: 110, height: 24),
                      SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(child: ShimmerBox(height: 76)),
                          SizedBox(width: AppSpacing.md),
                          Expanded(child: ShimmerBox(height: 76)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.detail});

  final DrawingDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = detail.summary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusPill(label: s.category.name, tone: StatusTone.info),
              if (detail.viewer.isPurchased)
                const StatusPill(
                  label: 'Purchased',
                  tone: StatusTone.success,
                  icon: Icons.check_circle_outline,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              s.title,
              key: const Key('detail-title'),
              style: theme.textTheme.headlineSmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (s.isFree)
                Text(
                  'Free',
                  key: const Key('detail-price'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppSemanticColors.of(context).success,
                  ),
                )
              else
                PriceText(
                  key: const Key('detail-price'),
                  paise: s.pricePaise,
                  style: theme.textTheme.headlineSmall,
                ),
              const Spacer(),
              if (s.ratingCount > 0) ...[
                Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: AppSemanticColors.of(context).warning,
                ),
                const SizedBox(width: 2),
                Text(
                  '${formatRating(s.avgRating)} (${s.ratingCount})',
                  style: theme.textTheme.titleSmall,
                ),
              ] else
                Text(
                  'No ratings yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plot size, area, floors, facing, city and category as a StatTile grid.
class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.summary});

  final DrawingSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final tiles = <(IconData, String, String)>[
      (Icons.straighten, formatPlotSize(s), 'Plot size'),
      (Icons.square_foot, formatArea(s.plotAreaSqft), 'Plot area'),
      (
        Icons.layers_outlined,
        '${s.floors}',
        s.floors == 1 ? 'Floor' : 'Floors',
      ),
      if (s.facing != null) (Icons.explore_outlined, s.facing!, 'Facing'),
      (Icons.place_outlined, s.city, 'City'),
      (Icons.category_outlined, s.category.name, 'Category'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth >= 600 ? 3 : 2;
          final tileWidth =
              (c.maxWidth - AppSpacing.md * (columns - 1)) / columns;
          return Wrap(
            key: const Key('spec-grid'),
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final (icon, value, label) in tiles)
                SizedBox(
                  width: tileWidth,
                  child: StatTile(icon: icon, value: value, label: label),
                ),
            ],
          );
        },
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
    final scheme = Theme.of(context).colorScheme;
    final v = detail.viewer;
    final unlocked = v.isOwner || v.isPurchased || v.canDownload;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Sheets',
          subtitle:
              unlocked
                  ? '${detail.sheets.length} included'
                  : '${detail.sheets.length} sheets unlock after purchase',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: AppCard(
            style: AppCardStyle.outlined,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < detail.sheets.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  ListTile(
                    key: Key('sheet-${detail.sheets[i].id}'),
                    leading: Icon(
                      unlocked ? Icons.lock_open_rounded : Icons.lock_outline,
                      color: unlocked ? scheme.primary : null,
                      key: Key(
                        unlocked
                            ? 'sheet-open-${detail.sheets[i].id}'
                            : 'sheet-locked-${detail.sheets[i].id}',
                      ),
                    ),
                    title: Text(sheetTypeLabel(detail.sheets[i].type)),
                    subtitle: Text(
                      unlocked
                          ? detail.sheets[i].fileName
                          : (detail.sheets[i].isPreview
                              ? 'Watermarked preview'
                              : 'Included with purchase'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: AppCard(
        key: const Key('architect-card'),
        onTap: onTap,
        semanticLabel:
            'Architect ${architect.fullName}, ${architect.city}. '
            'View profile',
        child: ExcludeSemantics(
          child: Row(
            children: [
              AppAvatar(
                name: architect.fullName,
                url: architect.avatarUrl,
                size: 52,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      architect.fullName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            architect.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        RatingLabel(
                          rating: architect.architectRating,
                          count: architect.ratingCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenceNote extends StatelessWidget {
  const _LicenceNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      child: AppCard(
        key: const Key('licence-note'),
        style: AppCardStyle.tonal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.gavel_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Licence', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You receive a non-exclusive licence to use this drawing '
                    'for your own projects. Resale or re-upload is not '
                    'permitted. Previews are watermarked; full sheets unlock '
                    'after purchase.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
