import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/plot_size_badge.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/shimmer.dart';
import '../domain/drawing_summary.dart';
import 'formatters.dart';

/// Hero tag shared by the card preview and the detail gallery. Scoped to the
/// enclosing Navigator (one per tab) so the same drawing shown in several tabs
/// never produces duplicate tags in a single route subtree.
String drawingHeroTag(BuildContext context, String drawingId) =>
    'drawing-hero-${identityHashCode(Navigator.maybeOf(context))}-$drawingId';

/// Image-first grid tile for a drawing: big preview with the plot-size badge
/// and price chip over it, then title, city and rating.
class DrawingCard extends StatelessWidget {
  const DrawingCard({
    super.key,
    required this.drawing,
    required this.onTap,
    this.favoriteAction,
    this.preview,
  });

  final DrawingSummary drawing;
  final VoidCallback onTap;

  /// Optional heart shown over the preview (top-left), e.g. in Favorites.
  final Widget? favoriteAction;

  /// Replaces the network preview image, e.g. a local file while uploading.
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizeMatch = drawing.sizeMatch;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                preview ??
                    Hero(
                      tag: drawingHeroTag(context, drawing.id),
                      child: DrawingPreviewImage(url: drawing.previewUrl),
                    ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x66000000)],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                if (favoriteAction != null)
                  Positioned(top: 4, left: 4, child: favoriteAction!),
                if (sizeMatch != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Chip(
                      label: formatSizeMatch(sizeMatch),
                      background: scheme.primary,
                      foreground: scheme.onPrimary,
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    runSpacing: 4,
                    children: [
                      PlotSizeBadge(
                        lengthFt: drawing.plotLengthFt,
                        breadthFt: drawing.plotBreadthFt,
                        onImage: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  drawing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        drawing.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _PriceChip(drawing: drawing),
                    if (drawing.ratingCount > 0)
                      RatingLabel(
                        rating: drawing.avgRating,
                        count: drawing.ratingCount,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.drawing});

  final DrawingSummary drawing;

  @override
  Widget build(BuildContext context) {
    final sem = AppSemanticColors.of(context);
    if (drawing.isFree) {
      return _Chip(
        label: 'FREE',
        background: sem.success,
        foreground: sem.onSuccess,
      );
    }
    return PriceText(
      paise: drawing.pricePaise,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style:
              Theme.of(context).textTheme.labelMedium
                  ?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  )
                  .tabular,
        ),
      ),
    );
  }
}

/// Watermarked preview image: shimmer while loading, fade-in, and a
/// blueprint-sheet fallback when missing or failed.
class DrawingPreviewImage extends StatelessWidget {
  const DrawingPreviewImage({super.key, required this.url, this.fit});

  final String? url;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final u = url;
    // Decorative: the card text already names the drawing.
    if (u == null) return const ExcludeSemantics(child: _PreviewFallback());
    return ExcludeSemantics(
      child: CachedNetworkImage(
        imageUrl: u,
        fit: fit ?? BoxFit.cover,
        fadeInDuration: AppMotion.base,
        placeholder: (_, __) => const Shimmer(child: ShimmerBox(radius: 0)),
        errorWidget: (_, __, ___) => const _PreviewFallback(),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.architecture,
          size: 36,
          color: scheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
