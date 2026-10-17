import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../drawings/presentation/discovery_routes.dart';
import 'featured_screen.dart';

/// Routes of the Featured tab; registered as one branch in `core/router/app_router.dart`.
final featuredRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.featured,
    builder: (_, __) => const FeaturedScreen(),
    routes: discoverySubRoutes(featuredPaths, includeSearch: false),
  ),
];
