import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../domain/drawing_summary.dart';
import 'drawing_card.dart';

const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  mainAxisExtent: 272,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
);
const _prefetchDistance = 4;
const _gridPadding = EdgeInsets.symmetric(horizontal: 16);

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
        SliverPadding(
          padding: _gridPadding,
          sliver: SliverGrid.builder(
            gridDelegate: _gridDelegate,
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final d = state.items[i];
              if (state.hasMore &&
                  state.loadMoreError == null &&
                  i >= state.items.length - _prefetchDistance) {
                // The grid only builds items near the viewport, so reaching
                // the tail means the user is about to hit the end.
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onLoadMore(),
                );
              }
              return DrawingCard(drawing: d, onTap: () => onTap(d));
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _PagedFooter(state: state, onRetry: onRetryMore),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ];
    },
  );
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid.builder(
        key: const Key('drawing-grid-skeleton'),
        gridDelegate: _gridDelegate,
        itemCount: 6,
        itemBuilder:
            (_, __) => DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
