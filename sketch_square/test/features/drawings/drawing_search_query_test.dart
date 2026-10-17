import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';

DrawingSearchQuery parse(String query) =>
    DrawingSearchQuery.fromQueryParameters(
      Uri.parse('/x?$query').queryParametersAll,
    );

void main() {
  test('default query has no parameters and no active filters', () {
    const q = DrawingSearchQuery();
    expect(q.toQueryParameters(), isEmpty);
    expect(q.activeFilterCount, 0);
  });

  test('serialises every filter using contract parameter names', () {
    const q = DrawingSearchQuery(
      q: ' villa ',
      categoryId: 'c1',
      length: 40,
      breadth: 30,
      unit: LengthUnit.m,
      tolerancePct: 20,
      cities: ['Pune', 'Mumbai'],
      minDrawingRating: 4,
      minArchitectRating: 3.5,
      priceType: PriceType.paid,
      minPricePaise: 100000,
      maxPricePaise: 500000,
      sort: DrawingSort.priceAsc,
    );
    expect(q.toQueryParameters(cursor: 'abc', limit: 20), {
      'q': 'villa',
      'categoryId': 'c1',
      'length': '40',
      'breadth': '30',
      'unit': 'm',
      'tolerancePct': '20',
      'city': ['Pune', 'Mumbai'],
      'minDrawingRating': '4.0',
      'minArchitectRating': '3.5',
      'priceType': 'paid',
      'minPricePaise': '100000',
      'maxPricePaise': '500000',
      'sort': 'price_asc',
      'cursor': 'abc',
      'limit': '20',
    });
    // category + size + 2 cities + 2 ratings + priceType + price range
    expect(q.activeFilterCount, 8);
  });

  test('omits default unit, tolerance and sort; tolerance needs a size', () {
    const q = DrawingSearchQuery(length: 30, breadth: 40, tolerancePct: 10);
    expect(q.toQueryParameters(), {'length': '30', 'breadth': '40'});
    expect(
      const DrawingSearchQuery(tolerancePct: 30).toQueryParameters(),
      isEmpty,
    );
  });

  test('round-trips through a URL, including repeated city params', () {
    const q = DrawingSearchQuery(
      q: 'north facing',
      length: 32.5,
      breadth: 50,
      cities: ['Pune', 'New Delhi'],
      priceType: PriceType.free,
      sort: DrawingSort.newest,
      tolerancePct: 15,
    );
    final uri = Uri(
      path: '/home/search',
      queryParameters: q.toQueryParameters(),
    );
    expect(uri.toString(), contains('city=Pune&city=New+Delhi'));
    expect(DrawingSearchQuery.fromQueryParameters(uri.queryParametersAll), q);
  });

  test('parsing ignores malformed values and clamps tolerance', () {
    final q = parse(
      'length=abc&breadth=10&tolerancePct=999&sort=bogus&priceType=x',
    );
    expect(q.hasPlotSize, isFalse);
    expect(q.tolerancePct, maxTolerancePct);
    expect(q.sort, DrawingSort.relevance);
    expect(q.priceType, PriceType.all);
    expect(parse('length=0&breadth=10').hasPlotSize, isFalse);
  });

  test('clearFilters keeps text and sort only', () {
    const q = DrawingSearchQuery(
      q: 'villa',
      sort: DrawingSort.newest,
      categoryId: 'c1',
      cities: ['Pune'],
    );
    expect(
      q.clearFilters(),
      const DrawingSearchQuery(q: 'villa', sort: DrawingSort.newest),
    );
  });
}
