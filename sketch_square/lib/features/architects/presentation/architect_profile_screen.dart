import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/formatters.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';
import '../domain/architect_summary.dart';
import 'architect_profile_controller.dart';

/// Public profile of an architect: header, key stats and their published
/// drawings.
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
        loading: () => const _ProfileSkeleton(),
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
                    child: _ProfileHeader(
                      architect: state.architect,
                      drawingCount: state.drawings.items.length,
                      hasMore: state.drawings.hasMore,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Drawings'),
                  ),
                  ...pagedDrawingSlivers(
                    value: AsyncData(state.drawings),
                    onTap: (d) => context.push(paths.drawing(d.id)),
                    onRetry: () => ref.invalidate(provider),
                    onLoadMore: notifier.loadMore,
                    onRetryMore: () => notifier.loadMore(retry: true),
                    empty: const EmptyState(
                      icon: Icons.architecture,
                      title: 'No drawings yet',
                      message: 'This architect has no published drawings.',
                      compact: true,
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
  const _ProfileHeader({
    required this.architect,
    required this.drawingCount,
    required this.hasMore,
  });

  final ArchitectSummary architect;
  final int drawingCount;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rated = architect.ratingCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: architect.fullName,
                url: architect.avatarUrl,
                size: 80,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      architect.fullName,
                      key: const Key('architect-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            architect.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppSemanticColors.of(context).warning,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            rated
                                ? '${formatRating(architect.architectRating)} '
                                    '(${architect.ratingCount} ratings)'
                                : 'No ratings yet',
                            key: const Key('architect-rating'),
                            maxLines: 1,
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
          const SizedBox(height: AppSpacing.lg),
          Row(
            key: const Key('architect-stats'),
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.star_outline_rounded,
                  value: rated ? formatRating(architect.architectRating) : '—',
                  label: 'Rating',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.architecture,
                  value: '$drawingCount${hasMore ? '+' : ''}',
                  label: 'Drawings',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 80, height: 80, circle: true),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 22),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 100, height: 14),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 140, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 84, radius: AppRadius.md)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: ShimmerBox(height: 84, radius: AppRadius.md)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: ShimmerBox(height: 84, radius: AppRadius.md)),
              ],
            ),
          ],
        ),
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
  Widget build(BuildContext context) => AppAvatar(
    name: architect.fullName,
    url: architect.avatarUrl,
    size: radius * 2,
  );
}
