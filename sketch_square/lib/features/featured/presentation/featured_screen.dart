import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../architects/data/architects_providers.dart';
import '../../architects/domain/architect_profile.dart';
import '../../drawings/data/drawings_providers.dart';
import '../../drawings/domain/drawing_search_query.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/drawing_search_controller.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';

const featuredPaths = DiscoveryPaths(AppRoutes.featured);

/// Featured tab: top architects and the highest-rated drawings, optionally
/// narrowed to one city.
class FeaturedScreen extends ConsumerStatefulWidget {
  const FeaturedScreen({super.key});

  @override
  ConsumerState<FeaturedScreen> createState() => _FeaturedScreenState();
}

class _FeaturedScreenState extends ConsumerState<FeaturedScreen> {
  String? _city;

  DrawingSearchQuery get _query => DrawingSearchQuery(
    sort: DrawingSort.drawingRating,
    cities: [if (_city != null) _city!],
  );

  @override
  Widget build(BuildContext context) {
    final feed = drawingSearchControllerProvider(_query);
    final top = ref.watch(topArchitectsProvider(_city));

    return Scaffold(
      appBar: AppBar(title: const Text('Featured')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topArchitectsProvider(_city));
          ref.invalidate(feed);
          await ref.read(feed.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CityPicker(
                selected: _city,
                onChanged: (c) => setState(() => _city = c),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Top architects',
                subtitle: 'Ranked by rating',
              ),
            ),
            SliverToBoxAdapter(
              child: top.when(
                loading: () => const _TopArchitectsSkeleton(),
                error:
                    (e, _) => _TopArchitectsError(
                      message: toApiException(e).message,
                      onRetry:
                          () => ref.invalidate(topArchitectsProvider(_city)),
                    ),
                data: (list) => _TopArchitects(items: list),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Highest-rated drawings'),
            ),
            ...pagedDrawingSlivers(
              value: ref.watch(feed),
              onTap: (d) => context.push(featuredPaths.drawing(d.id)),
              onRetry: () => ref.invalidate(feed),
              onLoadMore: () => ref.read(feed.notifier).loadMore(),
              onRetryMore: () => ref.read(feed.notifier).loadMore(retry: true),
              empty: const EmptyState(
                icon: Icons.star_outline_rounded,
                compact: true,
                title: 'Nothing featured yet',
                message: 'Try another city.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityPicker extends ConsumerWidget {
  const _CityPicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider).valueOrNull ?? const [];
    // Keep the current selection selectable even if the list has not loaded.
    final names = {
      for (final c in cities) c.city,
      if (selected != null) selected!,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DropdownButtonFormField<String?>(
            key: const Key('city-picker'),
            value: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All cities'),
              ),
              for (final name in names)
                DropdownMenuItem<String?>(value: name, child: Text(name)),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _TopArchitects extends StatelessWidget {
  const _TopArchitects({required this.items});

  final List<TopArchitect> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: AppCard(
          style: AppCardStyle.tonal,
          child: Text(
            'No architects have enough ratings yet.',
            key: const Key('top-architects-empty'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    // Wide windows wrap the cards instead of a sideways-scrolling strip.
    if (context.isWide) {
      return Padding(
        key: const Key('top-architects'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                height: _cardHeight(context),
                child: _ArchitectCard(rank: i + 1, entry: items[i]),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      height: _cardHeight(context),
      child: ListView.separated(
        key: const Key('top-architects'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder:
            (context, i) => _ArchitectCard(rank: i + 1, entry: items[i]),
      ),
    );
  }
}

const _cardWidth = 164.0;

/// Grows with the text scale so the card never overflows.
double _cardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return 172 + (scale - 1).clamp(0, 1) * 110;
}

class _ArchitectCard extends StatelessWidget {
  const _ArchitectCard({required this.rank, required this.entry});

  final int rank;
  final TopArchitect entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = entry.architect;
    final count = entry.drawingCount;
    return SizedBox(
      width: _cardWidth,
      child: AppCard(
        key: Key('top-architect-${a.id}'),
        style: AppCardStyle.outlined,
        onTap: () => context.push(featuredPaths.architect(a.id)),
        semanticLabel:
            '${a.fullName}, rank $rank, $count '
            '${count == 1 ? 'drawing' : 'drawings'}',
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(name: a.fullName, url: a.avatarUrl, size: 52),
                  const Spacer(),
                  _RankBadge(rank: rank),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                a.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                a.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  RatingLabel(rating: a.architectRating, count: a.ratingCount),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$count ${count == 1 ? 'drawing' : 'drawings'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final top = rank == 1;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: top ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.tabular.copyWith(
          color: top ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TopArchitectsSkeleton extends StatelessWidget {
  const _TopArchitectsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight(context),
      child: Shimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder:
              (_, __) => const ShimmerBox(
                width: _cardWidth,
                height: double.infinity,
                radius: AppRadius.lg,
              ),
        ),
      ),
    );
  }
}

class _TopArchitectsError extends StatelessWidget {
  const _TopArchitectsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: AppCard(
        style: AppCardStyle.tonal,
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(
              key: const Key('top-architects-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
