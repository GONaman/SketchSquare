import 'drawing_search_query_uri.dart';
import '../domain/drawing_search_query.dart';

/// Builds locations for the discovery sub-routes inside one tab, so the same
/// screens can be reached from Home (`/home/...`) and Featured (`/featured/...`)
/// while each tab keeps its own navigation stack.
class DiscoveryPaths {
  const DiscoveryPaths(this.base);

  final String base;

  static const searchSegment = 'search';
  static const drawingSegment = 'drawing';
  static const architectSegment = 'architect';

  String search([DrawingSearchQuery query = const DrawingSearchQuery()]) =>
      query.toLocation('$base/$searchSegment');

  String drawing(String id) => '$base/$drawingSegment/$id';

  String architect(String id) => '$base/$architectSegment/$id';
}
