import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import 'admin_refund_detail_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_verification_detail_screen.dart';
import 'admin_verifications_screen.dart';

/// Top-level (outside the tab shell) ADMIN routes; the redirect in
/// `authRedirect` keeps everyone else out.
final adminRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.admin,
    builder: (_, __) => const AdminVerificationsScreen(),
    routes: [
      GoRoute(
        path: 'verification/:id',
        builder:
            (_, state) =>
                AdminVerificationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'refunds',
        builder: (_, __) => const AdminRefundsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (_, state) =>
                    AdminRefundDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  ),
];
