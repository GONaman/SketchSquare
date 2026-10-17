import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drawing_card.dart' show DrawingPreviewImage;

part 'drawing_gallery.g.dart';

typedef GalleryImageResolver = ImageProvider Function(String url);

/// How gallery images are loaded. Overridden in tests to avoid the network.
@Riverpod(keepAlive: true)
GalleryImageResolver galleryImageResolver(Ref ref) =>
    (url) => CachedNetworkImageProvider(url);

/// Pinch-to-zoom, swipeable gallery of watermarked previews with a page
/// indicator. Tap opens the same gallery full screen.
class DrawingGallery extends ConsumerStatefulWidget {
  const DrawingGallery({
    super.key,
    required this.urls,
    this.height = 300,
    this.heroTag,
  });

  final List<String> urls;
  final double height;

  /// When set, the first image flies in from the matching card (see
  /// `drawingHeroTag`).
  final Object? heroTag;

  @override
  ConsumerState<DrawingGallery> createState() => _DrawingGalleryState();
}

class _DrawingGalleryState extends ConsumerState<DrawingGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder:
            (_) => _FullscreenGallery(urls: widget.urls, initialIndex: _index),
      ),
    );
  }

  // The flight shows a plain thumbnail so the PageView/controller is never
  // mounted twice.
  Widget _withHero(Widget child) {
    final tag = widget.heroTag;
    if (tag == null) return child;
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (_, __, ___, ____, _____) =>
              DrawingPreviewImage(url: widget.urls.first, fit: BoxFit.cover),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.urls.isEmpty) {
      return Container(
        key: const Key('gallery-empty'),
        height: widget.height,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.architecture,
          size: 56,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Semantics(
            button: true,
            label:
                widget.urls.length > 1
                    ? 'Drawing preview, ${widget.urls.length} images. '
                        'Open full screen'
                    : 'Drawing preview. Open full screen',
            child: GestureDetector(
              onTap: _openFullscreen,
              child: ExcludeSemantics(
                child: _withHero(
                  _GalleryView(
                    urls: widget.urls,
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _index = i),
                  ),
                ),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: _Pill(
                key: const Key('gallery-indicator'),
                label: '${_index + 1} / ${widget.urls.length}',
              ),
            ),
          const Positioned(
            left: 12,
            bottom: 12,
            child: _Pill(label: 'Preview · watermarked'),
          ),
        ],
      ),
    );
  }
}

class _GalleryView extends ConsumerWidget {
  const _GalleryView({
    required this.urls,
    required this.controller,
    this.onPageChanged,
  });

  final List<String> urls;
  final PageController controller;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolve = ref.watch(galleryImageResolverProvider);
    final scheme = Theme.of(context).colorScheme;
    return PhotoViewGallery.builder(
      pageController: controller,
      itemCount: urls.length,
      onPageChanged: onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
      ),
      loadingBuilder:
          (_, __) => const Center(child: CircularProgressIndicator()),
      builder:
          (_, i) => PhotoViewGalleryPageOptions(
            imageProvider: resolve(urls[i]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            errorBuilder:
                (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
          ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Preview'),
      ),
      body: _GalleryView(urls: widget.urls, controller: _controller),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
