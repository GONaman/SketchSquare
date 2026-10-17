import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/placeholder_screen.dart';
import '../domain/drawing_search_query.dart';
import 'discovery_paths.dart';
import 'search_screen.dart';

/// Sub-routes of a tab for the discovery flow: search results, drawing detail
/// and architect profile. Both Home and Featured mount them under their own
/// base path so each tab keeps its own stack.
List<RouteBase> discoverySubRoutes(
  DiscoveryPaths paths, {
  bool includeSearch = true,
}) => [
  if (includeSearch)
    GoRoute(
      path: DiscoveryPaths.searchSegment,
      builder:
          (_, state) => SearchScreen(
            paths: paths,
            query: DrawingSearchQuery.fromQueryParameters(
              state.uri.queryParametersAll,
            ),
            autofocus: state.extra == true,
          ),
    ),
  GoRoute(
    path: '${DiscoveryPaths.drawingSegment}/:id',
    builder:
        (_, __) =>
            const PlaceholderScreen(title: 'Drawing', icon: Icons.architecture),
  ),
  GoRoute(
    path: '${DiscoveryPaths.architectSegment}/:id',
    builder:
        (_, __) => const PlaceholderScreen(
          title: 'Architect',
          icon: Icons.person_outline,
        ),
  ),
];
