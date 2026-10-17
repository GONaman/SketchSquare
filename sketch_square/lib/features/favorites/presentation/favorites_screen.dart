import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';
import 'favorites_controller.dart';

/// Where drawings opened from the Profile tab live (see `profile_routes.dart`).
const favoritesPaths = DiscoveryPaths(AppRoutes.profile);

/// "Favorites": a grid of the drawings the user hearted. Tapping a heart
/// removes the drawing (rolled back with a message if the call fails).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    DrawingSummary d,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(favoritesControllerProvider.notifier).remove(d);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(favoritesControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            ...pagedDrawingSlivers(
              value: ref.watch(favoritesControllerProvider),
              onTap: (d) => context.push(favoritesPaths.drawing(d.id)),
              onRetry: () => ref.invalidate(favoritesControllerProvider),
              onLoadMore: notifier.loadMore,
              onRetryMore: notifier.retryLoadMore,
              favoriteActionFor:
                  (d) =>
                      _FavoriteHeart(onPressed: () => _remove(context, ref, d)),
              empty: const BlueprintEmptyState(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                message: 'Tap the heart on a drawing to save it here.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    key: const Key('favorite-toggle'),
    tooltip: 'Remove from favorites',
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: const Icon(Icons.favorite),
  );
}
