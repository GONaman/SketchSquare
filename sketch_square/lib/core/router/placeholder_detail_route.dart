import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/placeholder_screen.dart';
import 'routes.dart';

/// Placeholder sub-route under each tab (`/<tab>/details`) that lets tests
/// and early screens verify per-tab navigation stacks. Remove per tab once
/// the tab has real sub-routes.
final placeholderDetailRoute = GoRoute(
  path: AppRoutes.detailSegment,
  builder:
      (_, __) =>
          const PlaceholderScreen(title: 'Details', icon: Icons.architecture),
);
