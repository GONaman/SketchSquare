import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blueprint_empty_state.dart';
import '../domain/drawing_search_query.dart';
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
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
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
          PopupMenuButton<DrawingSort>(
            key: const Key('sort-menu'),
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (s) => _go(query.copyWith(sort: s)),
            itemBuilder:
                (_) => [
                  for (final s in DrawingSort.values)
                    CheckedPopupMenuItem(
                      value: s,
                      checked: s == query.sort,
                      child: Text(s.label),
                    ),
                ],
          ),
          IconButton(
            key: const Key('filters-button'),
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: const Icon(Icons.tune),
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
                  const SliverPadding(padding: EdgeInsets.only(top: 4)),
                  ...pagedDrawingSlivers(
                    value: results,
                    onTap: (d) => context.push(widget.paths.drawing(d.id)),
                    onRetry: () => ref.invalidate(provider),
                    onLoadMore: () => ref.read(provider.notifier).loadMore(),
                    onRetryMore:
                        () => ref.read(provider.notifier).loadMore(retry: true),
                    empty: _EmptySearch(
                      query: query,
                      onClearFilters: () => _go(query.clearFilters()),
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query, required this.onClearFilters});

  final DrawingSearchQuery query;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final hasFilters = query.activeFilterCount > 0;
    return BlueprintEmptyState(
      icon: Icons.search_off,
      title: 'No drawings found',
      message:
          query.hasPlotSize
              ? 'Try a larger tolerance or a nearby plot size.'
              : 'Try a different search or fewer filters.',
      action:
          hasFilters
              ? OutlinedButton(
                key: const Key('clear-filters'),
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              )
              : null,
    );
  }
}
