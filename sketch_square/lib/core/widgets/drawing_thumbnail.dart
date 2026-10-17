import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Square preview thumbnail with a neutral placeholder when there is no image.
class DrawingThumbnail extends StatelessWidget {
  const DrawingThumbnail({super.key, this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.architecture, color: scheme.onSurfaceVariant),
    );
    // Decorative: the surrounding row already carries the drawing title.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: size,
          height: size,
          child:
              url == null
                  ? placeholder
                  : CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => placeholder,
                    errorWidget: (_, __, ___) => placeholder,
                  ),
        ),
      ),
    );
  }
}
