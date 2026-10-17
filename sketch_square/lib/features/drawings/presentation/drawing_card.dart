import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/drawing_summary.dart';
import 'formatters.dart';

/// Grid tile for a drawing: preview, title, size, city, price/FREE and rating.
class DrawingCard extends StatelessWidget {
  const DrawingCard({super.key, required this.drawing, required this.onTap});

  final DrawingSummary drawing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizeMatch = drawing.sizeMatch;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DrawingPreviewImage(url: drawing.previewUrl),
                  if (sizeMatch != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _Badge(
                        label: formatSizeMatch(sizeMatch),
                        background: scheme.primary,
                        foreground: scheme.onPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drawing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatPlotSize(drawing)} · ${drawing.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (drawing.isFree)
                        _Badge(
                          label: 'FREE',
                          background: scheme.tertiaryContainer,
                          foreground: scheme.onTertiaryContainer,
                        )
                      else
                        Text(
                          formatPaise(drawing.pricePaise),
                          style: theme.textTheme.titleSmall,
                        ),
                      const Spacer(),
                      if (drawing.ratingCount > 0) ...[
                        const Icon(Icons.star_rounded, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          formatRating(drawing.avgRating),
                          style: theme.textTheme.bodySmall,
                        ),
                      ] else
                        Text(
                          'New',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
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

/// Watermarked preview image with a blueprint-style fallback.
class DrawingPreviewImage extends StatelessWidget {
  const DrawingPreviewImage({super.key, required this.url, this.fit});

  final String? url;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.architecture,
          size: 36,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final u = url;
    if (u == null) return fallback;
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
