import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'shimmer.dart';

/// Rounded square preview thumbnail with a neutral placeholder when there is
/// no image.
class DrawingThumbnail extends StatelessWidget {
  const DrawingThumbnail({super.key, this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.primaryContainer,
      child: Icon(
        Icons.architecture,
        color: scheme.primary.withValues(alpha: 0.6),
      ),
    );
    // Decorative: the surrounding row already carries the drawing title.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child:
                url == null
                    ? placeholder
                    : CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) =>
                              const Shimmer(child: ShimmerBox(radius: 0)),
                      errorWidget: (_, __, ___) => placeholder,
                    ),
          ),
        ),
      ),
    );
  }
}
