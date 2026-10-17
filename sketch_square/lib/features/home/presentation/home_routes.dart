import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import 'home_screen.dart';

/// Routes of the Home tab; registered as one branch in `core/router/app_router.dart`.
final homeRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.home,
    builder: (_, __) => const HomeScreen(),
    routes: [placeholderDetailRoute],
  ),
];
