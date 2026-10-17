import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/formatters.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';
import '../domain/architect_summary.dart';
import 'architect_profile_controller.dart';

/// Public profile of an architect: header plus their published drawings.
class ArchitectProfileScreen extends ConsumerWidget {
  const ArchitectProfileScreen({
    super.key,
    required this.architectId,
    required this.paths,
  });

  final String architectId;
  final DiscoveryPaths paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = architectProfileControllerProvider(architectId);
    final profile = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Architect')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(provider),
            ),
        data:
            (state) => RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProfileHeader(architect: state.architect),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'Drawings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  ...pagedDrawingSlivers(
                    value: AsyncData(state.drawings),
                    onTap: (d) => context.push(paths.drawing(d.id)),
                    onRetry: () => ref.invalidate(provider),
                    onLoadMore: notifier.loadMore,
                    onRetryMore: () => notifier.loadMore(retry: true),
                    empty: const BlueprintEmptyState(
                      icon: Icons.architecture,
                      title: 'No drawings yet',
                      message: 'This architect has no published drawings.',
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.architect});

  final ArchitectSummary architect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rated = architect.ratingCount > 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ArchitectAvatar(architect: architect, radius: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  architect.fullName,
                  key: const Key('architect-name'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        architect.city,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        rated
                            ? '${formatRating(architect.architectRating)} '
                                '(${architect.ratingCount} ratings)'
                            : 'No ratings yet',
                        key: const Key('architect-rating'),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
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

/// Network avatar with the initials as fallback.
class ArchitectAvatar extends StatelessWidget {
  const ArchitectAvatar({super.key, required this.architect, this.radius = 20});

  final ArchitectSummary architect;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = architect.avatarUrl;
    final initial =
        architect.fullName.trim().isEmpty
            ? '?'
            : architect.fullName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundImage: url == null ? null : CachedNetworkImageProvider(url),
      onBackgroundImageError: url == null ? null : (_, __) {},
      child: url == null ? Text(initial) : null,
    );
  }
}
