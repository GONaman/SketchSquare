import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/layout/adaptive_grid.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/shimmer.dart';
import '../domain/drawing_summary.dart';
import 'drawing_card.dart';

/// Card height grows with the text scale so the info block never overflows.
SliverGridDelegate _gridDelegate(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return AdaptiveGridDelegate(
    mainAxisExtent: 300 + (scale - 1).clamp(0, 1) * 160,
  );
}

const _prefetchDistance = 4;
const _gridPadding = EdgeInsets.symmetric(horizontal: AppSpacing.gutter);

/// Slivers for an infinite-scrolling drawing grid driven by an
/// `AsyncValue<PagedState<DrawingSummary>>`: skeletons while loading, an error
/// with retry, [empty] state, the grid, and a footer that triggers [onLoadMore]
/// when it scrolls into view (and offers a retry when that page failed).
List<Widget> pagedDrawingSlivers({
  required AsyncValue<PagedState<DrawingSummary>> value,
  required ValueChanged<DrawingSummary> onTap,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
  required VoidCallback onRetryMore,
  required Widget empty,
  Widget? Function(DrawingSummary drawing)? favoriteActionFor,
}) {
  return value.when(
    loading: () => [const _SkeletonGrid()],
    error:
        (e, _) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorRetry(
              message: toApiException(e).message,
              onRetry: onRetry,
            ),
          ),
        ],
    data: (state) {
      if (state.items.isEmpty) {
        return [SliverFillRemaining(hasScrollBody: false, child: empty)];
      }
      return [
        _DrawingGrid(
          items: state.items,
          canPrefetch: state.hasMore && state.loadMoreError == null,
          onTap: onTap,
          onLoadMore: onLoadMore,
          favoriteActionFor: favoriteActionFor,
        ),
        SliverToBoxAdapter(
          child: _PagedFooter(state: state, onRetry: onRetryMore),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ];
    },
  );
}

class _DrawingGrid extends StatelessWidget {
  const _DrawingGrid({
    required this.items,
    required this.canPrefetch,
    required this.onTap,
    required this.onLoadMore,
    required this.favoriteActionFor,
  });

  final List<DrawingSummary> items;
  final bool canPrefetch;
  final ValueChanged<DrawingSummary> onTap;
  final VoidCallback onLoadMore;
  final Widget? Function(DrawingSummary drawing)? favoriteActionFor;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(context),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final d = items[i];
          if (canPrefetch && i >= items.length - _prefetchDistance) {
            // The grid only builds items near the viewport, so reaching
            // the tail means the user is about to hit the end.
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
          }
          return DrawingCard(
            drawing: d,
            onTap: () => onTap(d),
            favoriteAction: favoriteActionFor?.call(d),
          );
        },
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid.builder(
        key: const Key('drawing-grid-skeleton'),
        gridDelegate: _gridDelegate(context),
        itemCount: 6,
        itemBuilder: (_, __) => const DrawingCardSkeleton(),
      ),
    );
  }
}

class _PagedFooter extends StatelessWidget {
  const _PagedFooter({required this.state, required this.onRetry});

  final PagedState<DrawingSummary> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Couldn’t load more. Retry'),
          ),
        ),
      );
    }
    // Idle spacer: items near the tail trigger the next page; the spinner only
    // shows while that request is in flight.
    if (!state.isLoadingMore) return const SizedBox(height: 56);
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
