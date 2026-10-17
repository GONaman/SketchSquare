import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import 'basket_screen.dart';
import 'checkout_screen.dart';
import 'order_result_screen.dart';

/// Routes of the Basket tab; registered as one branch in `core/router/app_router.dart`.
final basketRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.basket,
    builder: (_, __) => const BasketScreen(),
    routes: [
      GoRoute(path: 'checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: 'order-result',
        builder: (_, __) => const OrderResultScreen(),
      ),
    ],
  ),
];
