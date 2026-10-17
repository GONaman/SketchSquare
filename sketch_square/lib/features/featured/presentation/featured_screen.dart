import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../architects/data/architects_providers.dart';
import '../../architects/domain/architect_profile.dart';
import '../../architects/presentation/architect_profile_screen.dart';
import '../../drawings/data/drawings_providers.dart';
import '../../drawings/domain/drawing_search_query.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/drawing_search_controller.dart';
import '../../drawings/presentation/formatters.dart';
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
    final theme = Theme.of(context);
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Top architects',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: top.when(
                loading:
                    () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (e, _) => _TopArchitectsError(
                      message: toApiException(e).message,
                      onRetry:
                          () => ref.invalidate(topArchitectsProvider(_city)),
                    ),
                data: (list) => _TopArchitects(items: list),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Highest-rated drawings',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            ...pagedDrawingSlivers(
              value: ref.watch(feed),
              onTap: (d) => context.push(featuredPaths.drawing(d.id)),
              onRetry: () => ref.invalidate(feed),
              onLoadMore: () => ref.read(feed.notifier).loadMore(),
              onRetryMore: () => ref.read(feed.notifier).loadMore(retry: true),
              empty: const BlueprintEmptyState(
                icon: Icons.star_outline,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No architects have enough ratings yet.',
          key: const Key('top-architects-empty'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    Widget card(int i) {
      final a = items[i].architect;
      return SizedBox(
        width: 140,
        height: 132,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('top-architect-${a.id}'),
            onTap: () => context.push(featuredPaths.architect(a.id)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ArchitectAvatar(architect: a, radius: 24),
                  const SizedBox(height: 8),
                  Text(
                    a.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    '★ ${formatRating(a.architectRating)} · '
                    '${items[i].drawingCount} drawings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Wide windows wrap the cards instead of a sideways-scrolling strip.
    if (context.isWide) {
      return Padding(
        key: const Key('top-architects'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (var i = 0; i < items.length; i++) card(i)],
        ),
      );
    }
    return SizedBox(
      height: 132,
      child: ListView.separated(
        key: const Key('top-architects'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => card(i),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
