import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../drawings/data/drawings_providers.dart';
import '../../drawings/domain/drawing_search_query.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../../drawings/presentation/discovery_paths.dart';
import '../../drawings/presentation/drawing_search_controller.dart';
import '../../drawings/presentation/paged_drawing_slivers.dart';
import '../../drawings/presentation/plot_size_fields.dart';
import '../../../core/layout/layout.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tap_scale.dart';
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
    final feed = drawingSearchControllerProvider(homeFeedQuery);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      // The expanded top navigation bar already carries the brand.
      appBar: context.isExpanded ? null : AppBar(title: const Wordmark()),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _SearchEntry(
                      onTap:
                          () => context.push(homePaths.search(), extra: true),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: _PlotSizeHero(
                  controller: _plot,
                  onSearch: _searchByPlotSize,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Browse by category',
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xl,
                  AppSpacing.gutter,
                  AppSpacing.sm,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryChips(
                categories: categories.valueOrNull ?? const [],
                onCategory:
                    (c) => context.push(
                      homePaths.search(DrawingSearchQuery(categoryId: c.id)),
                    ),
                onRequest: _requestCategory,
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Latest drawings',
                subtitle: 'Freshly published by verified architects',
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

/// Category shortcuts: a sideways-scrolling strip on phones, a wrapping row on
/// wider windows so nothing is cut off.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.onCategory,
    required this.onRequest,
  });

  final List<CategoryRef> categories;
  final ValueChanged<CategoryRef> onCategory;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final c in categories)
        ActionChip(label: Text(c.name), onPressed: () => onCategory(c)),
      ActionChip(
        key: const Key('request-category-chip'),
        avatar: const Icon(Icons.add, size: 18),
        label: const Text('Request a category'),
        onPressed: onRequest,
      ),
    ];
    if (context.isWide) {
      return Padding(
        key: const Key('category-chips'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: chips,
        ),
      );
    }
    return SizedBox(
      height: 52,
      child: ListView(
        key: const Key('category-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: 2,
        ),
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: chip,
            ),
        ],
      ),
    );
  }
}

/// Hero card for the key feature: type a plot size, find matching drawings.
class _PlotSizeHero extends StatelessWidget {
  const _PlotSizeHero({required this.controller, required this.onSearch});

  final PlotSizeController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sem = AppSemanticColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(sem.ink, AppColors.blueprintBlue, 0.55)!,
            sem.ink,
          ],
        ),
        boxShadow: AppElevation.level2(scheme.brightness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: BlueprintGridPainter(
                  color: Colors.white,
                  spacing: 22,
                  majorEvery: 4,
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 16,
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: const Size(56, 42),
                  painter: _HeroGlyphPainter(AppColors.copperLight),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs,
                      AppSpacing.xs,
                      56,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEARCH BY PLOT SIZE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.copperLight,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'What’s your plot size?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: PlotSizeFields(
                            controller: controller,
                            onSubmitted: onSearch,
                            trailing: PrimaryButton(
                              key: const Key('plot-search-button'),
                              label: 'Search',
                              icon: Icons.search_rounded,
                              onPressed: onSearch,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGlyphPainter extends CustomPainter {
  const _HeroGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(10, 12, size.width - 12, size.height - 12);
    canvas.drawRect(r, p);
    canvas.drawLine(Offset(r.left, 4), Offset(r.right, 4), p);
    canvas.drawLine(Offset(r.left, 0), Offset(r.left, 8), p);
    canvas.drawLine(Offset(r.right, 0), Offset(r.right, 8), p);
    canvas.drawLine(Offset(2, r.top), Offset(2, r.bottom), p);
    canvas.drawLine(Offset(-2, r.top), Offset(6, r.top), p);
    canvas.drawLine(Offset(-2, r.bottom), Offset(6, r.bottom), p);
  }

  @override
  bool shouldRepaint(_HeroGlyphPainter old) => old.color != color;
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
      excludeSemantics: true,
      child: TapScale(
        child: Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.controlRadius,
            side: BorderSide(color: scheme.outline),
          ),
          child: InkWell(
            key: const Key('home-search-entry'),
            borderRadius: AppRadius.controlRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Search drawings by title or keyword',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
