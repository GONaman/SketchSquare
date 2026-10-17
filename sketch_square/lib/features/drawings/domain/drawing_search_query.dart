import 'package:freezed_annotation/freezed_annotation.dart';

import 'plot_size.dart';

part 'drawing_search_query.freezed.dart';

enum PriceType {
  all('all'),
  free('free'),
  paid('paid');

  const PriceType(this.apiValue);
  final String apiValue;

  static PriceType fromApi(String? value) => PriceType.values.firstWhere(
    (p) => p.apiValue == value,
    orElse: () => all,
  );
}

enum DrawingSort {
  relevance('relevance', 'Relevance'),
  priceAsc('price_asc', 'Price: low to high'),
  priceDesc('price_desc', 'Price: high to low'),
  drawingRating('drawing_rating', 'Drawing rating'),
  architectRating('architect_rating', 'Architect rating'),
  newest('newest', 'Newest');

  const DrawingSort(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static DrawingSort fromApi(String? value) => DrawingSort.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => relevance,
  );
}

const int defaultTolerancePct = 10;
const int minTolerancePct = 0;
const int maxTolerancePct = 50;

/// Search state for `GET /drawings/search`. Value-equal so it can key a Riverpod
/// family, and it round-trips to the API/route query parameters.
@freezed
abstract class DrawingSearchQuery with _$DrawingSearchQuery {
  const DrawingSearchQuery._();

  const factory DrawingSearchQuery({
    @Default('') String q,
    String? categoryId,
    double? length,
    double? breadth,
    @Default(LengthUnit.ft) LengthUnit unit,
    @Default(defaultTolerancePct) int tolerancePct,
    @Default(<String>[]) List<String> cities,
    double? minDrawingRating,
    double? minArchitectRating,
    @Default(PriceType.all) PriceType priceType,
    int? minPricePaise,
    int? maxPricePaise,
    @Default(DrawingSort.relevance) DrawingSort sort,
  }) = _DrawingSearchQuery;

  bool get hasPlotSize => length != null && breadth != null;
  bool get hasPriceRange => minPricePaise != null || maxPricePaise != null;

  /// Number of active filters (everything except text query and sort).
  /// Plot size counts once, tolerance is part of it.
  int get activeFilterCount =>
      (categoryId != null ? 1 : 0) +
      (hasPlotSize ? 1 : 0) +
      cities.length +
      (minDrawingRating != null ? 1 : 0) +
      (minArchitectRating != null ? 1 : 0) +
      (priceType != PriceType.all ? 1 : 0) +
      (hasPriceRange ? 1 : 0);

  /// Same text query and sort, every filter cleared.
  DrawingSearchQuery clearFilters() => DrawingSearchQuery(q: q, sort: sort);

  /// Query parameters for the API and the route URL (they are identical).
  /// Default values are omitted. `city` is repeated.
  Map<String, dynamic> toQueryParameters({String? cursor, int? limit}) {
    final text = q.trim();
    return {
      if (text.isNotEmpty) 'q': text,
      if (categoryId != null) 'categoryId': categoryId,
      if (hasPlotSize) ...{
        'length': formatDimension(length!),
        'breadth': formatDimension(breadth!),
        if (unit != LengthUnit.ft) 'unit': unit.apiValue,
        if (tolerancePct != defaultTolerancePct)
          'tolerancePct': '$tolerancePct',
      },
      if (cities.isNotEmpty) 'city': cities,
      if (minDrawingRating != null) 'minDrawingRating': '$minDrawingRating',
      if (minArchitectRating != null)
        'minArchitectRating': '$minArchitectRating',
      if (priceType != PriceType.all) 'priceType': priceType.apiValue,
      if (minPricePaise != null) 'minPricePaise': '$minPricePaise',
      if (maxPricePaise != null) 'maxPricePaise': '$maxPricePaise',
      if (sort != DrawingSort.relevance) 'sort': sort.apiValue,
      if (cursor != null) 'cursor': cursor,
      if (limit != null) 'limit': '$limit',
    };
  }

  /// Parses route/query parameters. Unknown or malformed values are ignored.
  factory DrawingSearchQuery.fromQueryParameters(
    Map<String, List<String>> params,
  ) {
    String? one(String key) {
      final v = params[key];
      return v == null || v.isEmpty || v.first.isEmpty ? null : v.first;
    }

    final length = double.tryParse(one('length') ?? '');
    final breadth = double.tryParse(one('breadth') ?? '');
    final sizeOk =
        length != null && breadth != null && length > 0 && breadth > 0;
    return DrawingSearchQuery(
      q: one('q') ?? '',
      categoryId: one('categoryId'),
      length: sizeOk ? length : null,
      breadth: sizeOk ? breadth : null,
      unit: LengthUnit.fromApi(one('unit')),
      tolerancePct: (int.tryParse(one('tolerancePct') ?? '') ??
              defaultTolerancePct)
          .clamp(minTolerancePct, maxTolerancePct),
      cities: [
        for (final c in params['city'] ?? const <String>[])
          if (c.isNotEmpty) c,
      ],
      minDrawingRating: double.tryParse(one('minDrawingRating') ?? ''),
      minArchitectRating: double.tryParse(one('minArchitectRating') ?? ''),
      priceType: PriceType.fromApi(one('priceType')),
      minPricePaise: int.tryParse(one('minPricePaise') ?? ''),
      maxPricePaise: int.tryParse(one('maxPricePaise') ?? ''),
      sort: DrawingSort.fromApi(one('sort')),
    );
  }
}
