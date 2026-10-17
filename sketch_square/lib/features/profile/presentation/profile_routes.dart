import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import '../../purchases/presentation/purchases_screen.dart';
import 'profile_screen.dart';

/// Routes of the Profile tab; registered as one branch in `core/router/app_router.dart`.
final profileRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.profile,
    builder: (_, __) => const ProfileScreen(),
    routes: [
      GoRoute(path: 'purchases', builder: (_, __) => const PurchasesScreen()),
      placeholderDetailRoute,
    ],
  ),
];
