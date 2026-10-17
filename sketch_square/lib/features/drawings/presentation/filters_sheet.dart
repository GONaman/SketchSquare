import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/drawings_providers.dart';
import '../domain/drawing_search_query.dart';
import '../domain/plot_size.dart';
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
    final categories = ref.watch(categoriesProvider);
    final cities = ref.watch(citiesProvider);
    final free = _draft.priceType == PriceType.free;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  section(
                    'Plot size',
                    PlotSizeFields(controller: _plot, showTolerance: true),
                  ),
                  section(
                    'Category',
                    categories.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Couldn’t load categories'),
                      data:
                          (list) => Wrap(
                            spacing: 8,
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
                  section(
                    'City',
                    cities.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Couldn’t load cities'),
                      data: (list) {
                        final names = {
                          ...list.map((c) => c.city),
                          ..._draft.cities,
                        };
                        if (names.isEmpty) return const Text('No cities yet');
                        return Wrap(
                          spacing: 8,
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
                  section(
                    'Price',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<PriceType>(
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
                        const SizedBox(height: 8),
                        Text(
                          free ? 'Free drawings only' : _priceLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                        RangeSlider(
                          key: const Key('price-range'),
                          values: _priceRange,
                          min: 0,
                          max: _priceSteps.toDouble(),
                          divisions: _priceSteps,
                          onChanged: free ? null : _setPriceRange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  key: const Key('filters-reset'),
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('filters-apply'),
                  onPressed: _apply,
                  child: const Text('Show results'),
                ),
              ],
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
      spacing: 8,
      children: [
        for (final option in _ratingOptions)
          ChoiceChip(
            key: Key('$keyPrefix-${option ?? 'any'}'),
            label: Text(option == null ? 'Any' : '${formatRating(option)}+'),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}
