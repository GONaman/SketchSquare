import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/drawings_providers.dart';
import '../domain/drawing_search_query.dart';
import '../domain/plot_size.dart';
import '../../../core/widgets/widgets.dart';
import 'formatters.dart';
import 'plot_size_fields.dart';

/// Shows the filters bottom sheet. Resolves to the edited query on "Show
/// results" (or the cleared-filters query on "Reset"), null when dismissed.
Future<DrawingSearchQuery?> showFiltersSheet(
  BuildContext context,
  DrawingSearchQuery initial,
) {
  return showModalBottomSheet<DrawingSearchQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => _FiltersSheet(initial: initial),
  );
}

const _ratingOptions = <double?>[null, 3, 3.5, 4, 4.5];
const _priceStepPaise = 50000; // ₹500 per slider step
const _priceSteps = 100; // up to ₹50,000

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.initial});

  final DrawingSearchQuery initial;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late DrawingSearchQuery _draft = widget.initial;
  late final PlotSizeController _plot = PlotSizeController(
    length: widget.initial.length,
    breadth: widget.initial.breadth,
    unit: widget.initial.unit,
    tolerancePct: widget.initial.tolerancePct,
  );

  @override
  void dispose() {
    _plot.dispose();
    super.dispose();
  }

  RangeValues get _priceRange => RangeValues(
    ((_draft.minPricePaise ?? 0) / _priceStepPaise).clamp(
      0.0,
      _priceSteps.toDouble(),
    ),
    _draft.maxPricePaise == null
        ? _priceSteps.toDouble()
        : (_draft.maxPricePaise! / _priceStepPaise).clamp(
          0.0,
          _priceSteps.toDouble(),
        ),
  );

  void _setPriceRange(RangeValues v) {
    setState(() {
      _draft = _draft.copyWith(
        minPricePaise: v.start <= 0 ? null : v.start.round() * _priceStepPaise,
        maxPricePaise:
            v.end >= _priceSteps ? null : v.end.round() * _priceStepPaise,
      );
    });
  }

  String get _priceLabel {
    final min = _draft.minPricePaise;
    final max = _draft.maxPricePaise;
    if (min == null && max == null) return 'Any price';
    final lo = formatPaise(min ?? 0);
    return max == null ? '$lo and above' : '$lo – ${formatPaise(max)}';
  }

  void _apply() {
    final plot = _plot.validate(allowEmpty: true);
    if (!plot.isValid) return;
    final withSize =
        plot.hasSize
            ? _draft.copyWith(
              length: plot.length,
              breadth: plot.breadth,
              unit: _plot.unit,
              tolerancePct: _plot.tolerancePct,
            )
            : _draft.copyWith(
              length: null,
              breadth: null,
              unit: LengthUnit.ft,
              tolerancePct: defaultTolerancePct,
            );
    Navigator.of(context).pop(withSize);
  }

  void _reset() => Navigator.of(context).pop(_draft.clearFilters());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = ref.watch(categoriesProvider);
    final cities = ref.watch(citiesProvider);
    final free = _draft.priceType == PriceType.free;
    final hasChanges =
        _draft.activeFilterCount > 0 ||
        _plot.peekSize() != null ||
        _draft.sort != DrawingSort.relevance;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    final divider = Divider(height: 1, color: scheme.outlineVariant);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filters', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  key: const Key('filters-reset'),
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          divider,
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section(
                    'Plot size',
                    PlotSizeFields(controller: _plot, showTolerance: true),
                  ),
                  divider,
                  section(
                    'Price',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<PriceType>(
                            key: const Key('price-type'),
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: PriceType.all,
                                label: Text('Both'),
                              ),
                              ButtonSegment(
                                value: PriceType.free,
                                label: Text('Free'),
                              ),
                              ButtonSegment(
                                value: PriceType.paid,
                                label: Text('Paid'),
                              ),
                            ],
                            selected: {_draft.priceType},
                            onSelectionChanged:
                                (s) => setState(() {
                                  _draft = _draft.copyWith(
                                    priceType: s.first,
                                    minPricePaise:
                                        s.first == PriceType.free
                                            ? null
                                            : _draft.minPricePaise,
                                    maxPricePaise:
                                        s.first == PriceType.free
                                            ? null
                                            : _draft.maxPricePaise,
                                  );
                                }),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          free ? 'Free drawings only' : _priceLabel,
                          key: const Key('price-label'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                free
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                          ),
                        ),
                        RangeSlider(
                          key: const Key('price-range'),
                          values: _priceRange,
                          min: 0,
                          max: _priceSteps.toDouble(),
                          divisions: _priceSteps,
                          onChanged: free ? null : _setPriceRange,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹0', style: theme.textTheme.bodySmall),
                            Text('₹50,000+', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  divider,
                  section(
                    'Category',
                    categories.when(
                      loading: () => const ShimmerBox(height: 40),
                      error: (_, __) => const Text('Couldn’t load categories'),
                      data:
                          (list) => Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _draft.categoryId == null,
                                onSelected:
                                    (_) => setState(
                                      () =>
                                          _draft = _draft.copyWith(
                                            categoryId: null,
                                          ),
                                    ),
                              ),
                              for (final c in list)
                                ChoiceChip(
                                  label: Text(c.name),
                                  selected: _draft.categoryId == c.id,
                                  onSelected:
                                      (_) => setState(
                                        () =>
                                            _draft = _draft.copyWith(
                                              categoryId: c.id,
                                            ),
                                      ),
                                ),
                            ],
                          ),
                    ),
                  ),
                  divider,
                  section(
                    'City',
                    cities.when(
                      loading: () => const ShimmerBox(height: 40),
                      error: (_, __) => const Text('Couldn’t load cities'),
                      data: (list) {
                        final names = {
                          ...list.map((c) => c.city),
                          ..._draft.cities,
                        };
                        if (names.isEmpty) return const Text('No cities yet');
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final name in names)
                              FilterChip(
                                label: Text(name),
                                selected: _draft.cities.contains(name),
                                onSelected:
                                    (on) => setState(() {
                                      final next = [..._draft.cities];
                                      on ? next.add(name) : next.remove(name);
                                      _draft = _draft.copyWith(cities: next);
                                    }),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  divider,
                  section(
                    'Drawing rating',
                    _RatingChips(
                      keyPrefix: 'drawing-rating',
                      value: _draft.minDrawingRating,
                      onChanged:
                          (v) => setState(
                            () => _draft = _draft.copyWith(minDrawingRating: v),
                          ),
                    ),
                  ),
                  divider,
                  section(
                    'Architect rating',
                    _RatingChips(
                      keyPrefix: 'architect-rating',
                      value: _draft.minArchitectRating,
                      onChanged:
                          (v) => setState(
                            () =>
                                _draft = _draft.copyWith(minArchitectRating: v),
                          ),
                    ),
                  ),
                  divider,
                  section(
                    'Sort by',
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final sort in DrawingSort.values)
                          ChoiceChip(
                            key: Key('sort-${sort.apiValue}'),
                            label: Text(sort.label),
                            selected: _draft.sort == sort,
                            onSelected:
                                (_) => setState(
                                  () => _draft = _draft.copyWith(sort: sort),
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  key: const Key('filters-apply'),
                  label: hasChanges ? 'Show results' : 'Show all drawings',
                  onPressed: _apply,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChips extends StatelessWidget {
  const _RatingChips({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in _ratingOptions)
          ChoiceChip(
            key: Key('$keyPrefix-${option ?? 'any'}'),
            avatar:
                option == null
                    ? null
                    : Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppSemanticColors.of(context).warning,
                    ),
            label: Text(option == null ? 'Any' : '${formatRating(option)}+'),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}
