import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout.dart';
import '../../../core/router/routes.dart';
import 'admin_plagiarism_screen.dart';
import 'admin_refund_detail_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_verification_detail_screen.dart';
import 'admin_verifications_screen.dart';

Widget _framed(Widget screen) =>
    ContentFrame(width: ContentWidth.list, child: screen);

/// Top-level (outside the tab shell) ADMIN routes; the redirect in
/// `authRedirect` keeps everyone else out.
final adminRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.admin,
    builder: (_, __) => _framed(const AdminVerificationsScreen()),
    routes: [
      GoRoute(
        path: 'verification/:id',
        builder:
            (_, state) => _framed(
              AdminVerificationDetailScreen(id: state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: 'plagiarism',
        builder: (_, __) => _framed(const AdminPlagiarismScreen()),
      ),
      GoRoute(
        path: 'refunds',
        builder: (_, __) => _framed(const AdminRefundsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (_, state) => _framed(
                  AdminRefundDetailScreen(id: state.pathParameters['id']!),
                ),
          ),
        ],
      ),
    ],
  ),
];
