import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import '../../purchases/presentation/purchases_screen.dart';
import 'edit_contact_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Routes of the Profile tab; registered as one branch in `core/router/app_router.dart`.
/// Wallet and manage-drawings add their own sub-routes here / in their feature.
final profileRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.profile,
    builder: (_, __) => const ProfileScreen(),
    routes: [
      GoRoute(path: 'purchases', builder: (_, __) => const PurchasesScreen()),
      GoRoute(path: 'edit', builder: (_, __) => const EditContactScreen()),
      GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
      placeholderDetailRoute,
    ],
  ),
];
