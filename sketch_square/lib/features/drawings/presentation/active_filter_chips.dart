import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/drawings_providers.dart';
import '../domain/drawing_search_query.dart';
import '../domain/plot_size.dart';
import 'formatters.dart';

/// Removable chips for every active filter of [query].
class ActiveFilterChips extends ConsumerWidget {
  const ActiveFilterChips({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final DrawingSearchQuery query;
  final ValueChanged<DrawingSearchQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final chips = <(String, DrawingSearchQuery)>[
      if (query.hasPlotSize)
        (
          '${formatDimension(query.length!)}×${formatDimension(query.breadth!)} '
              '${query.unit.apiValue} ±${query.tolerancePct}%',
          query.copyWith(
            length: null,
            breadth: null,
            unit: LengthUnit.ft,
            tolerancePct: defaultTolerancePct,
          ),
        ),
      if (query.categoryId != null)
        (
          categories
                  .where((c) => c.id == query.categoryId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Category',
          query.copyWith(categoryId: null),
        ),
      for (final city in query.cities)
        (city, query.copyWith(cities: [...query.cities]..remove(city))),
      if (query.minDrawingRating != null)
        (
          'Drawing ${formatRating(query.minDrawingRating!)}+ ★',
          query.copyWith(minDrawingRating: null),
        ),
      if (query.minArchitectRating != null)
        (
          'Architect ${formatRating(query.minArchitectRating!)}+ ★',
          query.copyWith(minArchitectRating: null),
        ),
      if (query.priceType != PriceType.all)
        (
          query.priceType == PriceType.free ? 'Free' : 'Paid',
          query.copyWith(priceType: PriceType.all),
        ),
      if (query.hasPriceRange)
        (
          query.maxPricePaise == null
              ? '${formatPaise(query.minPricePaise ?? 0)}+'
              : '${formatPaise(query.minPricePaise ?? 0)} – '
                  '${formatPaise(query.maxPricePaise!)}',
          query.copyWith(minPricePaise: null, maxPricePaise: null),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const Key('active-filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, next) = chips[i];
          return InputChip(
            label: Text(label),
            onDeleted: () => onChanged(next),
            deleteButtonTooltipMessage: 'Remove $label',
          );
        },
      ),
    );
  }
}
