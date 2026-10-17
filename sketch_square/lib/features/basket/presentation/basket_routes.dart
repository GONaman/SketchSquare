import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import 'basket_screen.dart';

/// Routes of the Basket tab; registered as one branch in `core/router/app_router.dart`.
final basketRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.basket,
    builder: (_, __) => const BasketScreen(),
    routes: [placeholderDetailRoute],
  ),
];
