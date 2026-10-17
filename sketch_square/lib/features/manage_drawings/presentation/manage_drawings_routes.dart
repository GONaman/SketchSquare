import 'package:go_router/go_router.dart';

import '../../../core/layout/layout.dart';
import '../../../core/router/routes.dart';
import 'manage_drawings_screen.dart';

/// Top-level (full screen, above the tab shell) route for the seller's drawing
/// list. Link to it with `context.push(AppRoutes.manageDrawings)`.
final manageDrawingsRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.manageDrawings,
    builder:
        (_, __) => const ContentFrame(
          width: ContentWidth.list,
          child: ManageDrawingsScreen(),
        ),
  ),
];
