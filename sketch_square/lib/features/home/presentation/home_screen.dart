import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../drawings/data/drawings_providers.dart';
import '../../drawings/domain/drawing_search_query.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/drawing_search_controller.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';
import '../../drawings/presentation/plot_size_fields.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import 'request_category_sheet.dart';

const homePaths = DiscoveryPaths(AppRoutes.home);

/// Default home feed: newest published drawings.
const homeFeedQuery = DrawingSearchQuery(sort: DrawingSort.newest);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _plot = PlotSizeController();

  @override
  void dispose() {
    _plot.dispose();
    super.dispose();
  }

  void _searchByPlotSize() {
    final v = _plot.validate();
    if (!v.hasSize) return;
    context.push(
      homePaths.search(
        DrawingSearchQuery(
          length: v.length,
          breadth: v.breadth,
          unit: _plot.unit,
          tolerancePct: _plot.tolerancePct,
        ),
      ),
    );
  }

  Future<void> _requestCategory() async {
    final sent = await showRequestCategorySheet(context);
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! We’ll review your category.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feed = drawingSearchControllerProvider(homeFeedQuery);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(feed);
          await ref.read(feed.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SearchEntry(
                  onTap: () => context.push(homePaths.search(), extra: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  key: const Key('category-chips'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final c in categories.valueOrNull ?? const [])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(c.name),
                          onPressed:
                              () => context.push(
                                homePaths.search(
                                  DrawingSearchQuery(categoryId: c.id),
                                ),
                              ),
                        ),
                      ),
                    ActionChip(
                      key: const Key('request-category-chip'),
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Request a category'),
                      onPressed: _requestCategory,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Search by plot size',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PlotSizeFields(
                          controller: _plot,
                          onSubmitted: _searchByPlotSize,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('plot-search-button'),
                            onPressed: _searchByPlotSize,
                            child: const Text('Find drawings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Latest drawings',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            ...pagedDrawingSlivers(
              value: ref.watch(feed),
              onTap: (d) => context.push(homePaths.drawing(d.id)),
              onRetry: () => ref.invalidate(feed),
              onLoadMore: () => ref.read(feed.notifier).loadMore(),
              onRetryMore: () => ref.read(feed.notifier).loadMore(retry: true),
              empty: const BlueprintEmptyState(
                icon: Icons.architecture,
                title: 'No drawings yet',
                message: 'Published drawings will show up here.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Search drawings',
      child: InkWell(
        key: const Key('home-search-entry'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search drawings by title or keyword',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
