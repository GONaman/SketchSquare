import '../domain/drawing_search_query.dart';

extension DrawingSearchQueryUri on DrawingSearchQuery {
  /// `path?length=30&breadth=40&city=Pune&city=Goa` (the API parameter names).
  String toLocation(String path) {
    final params = toQueryParameters();
    if (params.isEmpty) return path;
    return Uri(path: path, queryParameters: params).toString();
  }
}
