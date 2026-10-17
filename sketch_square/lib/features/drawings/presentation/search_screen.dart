import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pagination/paged_state.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/drawing_search_query.dart';
import '../domain/drawing_summary.dart';
import '../domain/plot_size.dart';
import 'active_filter_chips.dart';
import 'discovery_paths.dart';
import 'drawing_search_controller.dart';
import 'filters_sheet.dart';
import 'paged_drawing_slivers.dart';

const searchDebounce = Duration(milliseconds: 400);

/// Search results. The [query] comes from the URL (so filters survive
/// navigation and can be deep-linked); every change navigates to a new URL.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    required this.paths,
    required this.query,
    this.autofocus = false,
  });

  final DiscoveryPaths paths;
  final DrawingSearchQuery query;
  final bool autofocus;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _text = TextEditingController(
    text: widget.query.q,
  );
  Timer? _debounce;

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    // Back/forward or a removed chip changed `q` from outside the field.
    if (widget.query.q.trim() != _text.text.trim()) {
      _text.text = widget.query.q;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _go(DrawingSearchQuery next) {
    if (!mounted || next == widget.query) return;
    context.go(widget.paths.search(next));
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      searchDebounce,
      () => _go(widget.query.copyWith(q: value.trim())),
    );
  }

  void _submitNow(String value) {
    _debounce?.cancel();
    _go(widget.query.copyWith(q: value.trim()));
  }

  Future<void> _openFilters() async {
    final result = await showFiltersSheet(context, widget.query);
    if (result != null) _go(result);
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    final provider = drawingSearchControllerProvider(query);
    final results = ref.watch(provider);
    final filterCount = query.activeFilterCount;

    final loaded = results.valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const Key('search-field'),
          controller: _text,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          onChanged: _onTextChanged,
          onSubmitted: _submitNow,
          decoration: InputDecoration(
            hintText: 'Search drawings',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: ListenableBuilder(
              listenable: _text,
              builder:
                  (_, __) =>
                      _text.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _text.clear();
                              _submitNow('');
                            },
                          ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.md,
            ),
            child: IconButton(
              key: const Key('filters-button'),
              tooltip: 'Filters',
              onPressed: _openFilters,
              style:
                  filterCount > 0
                      ? IconButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                      )
                      : IconButton.styleFrom(
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
              icon: Badge(
                isLabelVisible: filterCount > 0,
                label: Text('$filterCount'),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ActiveFilterChips(query: query, onChanged: _go),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ResultsHeader(
                      query: query,
                      loaded: loaded,
                      onSort: (s) => _go(query.copyWith(sort: s)),
                    ),
                  ),
                  ...pagedDrawingSlivers(
                    value: results,
                    onTap: (d) => context.push(widget.paths.drawing(d.id)),
                    onRetry: () => ref.invalidate(provider),
                    onLoadMore: () => ref.read(provider.notifier).loadMore(),
                    onRetryMore:
                        () => ref.read(provider.notifier).loadMore(retry: true),
                    empty: _EmptySearch(
                      query: query,
                      onChanged: _go,
                      onOpenFilters: _openFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "12 drawings" (or "20+" while more pages exist; the API has no total),
/// what the plot search covers, and the sort pill.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.query,
    required this.loaded,
    required this.onSort,
  });

  final DrawingSearchQuery query;
  final PagedState<DrawingSummary>? loaded;
  final ValueChanged<DrawingSort> onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = loaded?.items.length;
    final headline =
        count == null
            ? 'Searching…'
            : '$count${loaded!.hasMore ? '+' : ''} '
                '${count == 1 && !loaded!.hasMore ? 'drawing' : 'drawings'}';
    final unit = query.unit.apiValue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  key: const Key('result-count'),
                  style: theme.textTheme.titleMedium,
                ),
                if (query.hasPlotSize)
                  Text(
                    'Within ±${query.tolerancePct}% of '
                    '${formatDimension(query.length!)}×'
                    '${formatDimension(query.breadth!)} $unit · '
                    'rotated plots included',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<DrawingSort>(
            key: const Key('sort-menu'),
            tooltip: 'Sort',
            initialValue: query.sort,
            onSelected: onSort,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
            itemBuilder:
                (_) => [
                  for (final s in DrawingSort.values)
                    CheckedPopupMenuItem(
                      value: s,
                      checked: s == query.sort,
                      child: Text(s.label),
                    ),
                ],
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    query.sort == DrawingSort.relevance
                        ? 'Sort'
                        : query.sort.label,
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({
    required this.query,
    required this.onChanged,
    required this.onOpenFilters,
  });

  final DrawingSearchQuery query;
  final ValueChanged<DrawingSearchQuery> onChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final otherFilters =
        query.activeFilterCount - (query.hasPlotSize ? 1 : 0) > 0;
    if (query.hasPlotSize) {
      final size =
          '${formatDimension(query.length!)}×${formatDimension(query.breadth!)} '
          '${query.unit.apiValue}';
      final canWiden = query.tolerancePct < maxTolerancePct;
      final widened = (query.tolerancePct + 10).clamp(0, maxTolerancePct);
      return EmptyState(
        icon: Icons.straighten_rounded,
        variant: BlueprintArtVariant.plot,
        title: 'No drawings near $size',
        message:
            canWiden
                ? 'Nothing within ±${query.tolerancePct}% yet. Try widening '
                    'the tolerance or a nearby plot size.'
                : 'Nothing close to this plot size yet. Try a nearby size or '
                    'fewer filters.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canWiden)
              PrimaryButton(
                key: const Key('widen-tolerance'),
                expand: false,
                icon: Icons.unfold_more_rounded,
                label: 'Widen to ±$widened%',
                onPressed:
                    () => onChanged(query.copyWith(tolerancePct: widened)),
              )
            else
              PrimaryButton(
                key: const Key('clear-plot-size'),
                expand: false,
                label: 'Clear plot size',
                onPressed:
                    () => onChanged(
                      query.copyWith(
                        length: null,
                        breadth: null,
                        unit: LengthUnit.ft,
                        tolerancePct: defaultTolerancePct,
                      ),
                    ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (otherFilters)
              SecondaryButton(
                key: const Key('clear-filters'),
                expand: false,
                label: 'Clear all filters',
                onPressed: () => onChanged(query.clearFilters()),
              )
            else
              TextButton(
                onPressed: onOpenFilters,
                child: const Text('Edit plot size'),
              ),
          ],
        ),
      );
    }
    final hasFilters = query.activeFilterCount > 0;
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No drawings found',
      message: 'Try a different search or fewer filters.',
      action:
          hasFilters
              ? SecondaryButton(
                key: const Key('clear-filters'),
                label: 'Clear filters',
                expand: false,
                onPressed: () => onChanged(query.clearFilters()),
              )
              : null,
    );
  }
}
