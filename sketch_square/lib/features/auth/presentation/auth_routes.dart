import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/placeholder_screen.dart';
import 'splash_screen.dart';

/// Non-tab routes of the auth feature; spread into the top-level routes in
/// `core/router/app_router.dart`.
final authRoutes = <RouteBase>[
  GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
  GoRoute(
    path: AppRoutes.signIn,
    builder:
        (_, __) => const PlaceholderScreen(title: 'Sign in', icon: Icons.login),
  ),
  GoRoute(
    path: AppRoutes.verificationPending,
    builder:
        (_, __) => const PlaceholderScreen(
          title: 'Verification pending',
          icon: Icons.hourglass_empty,
        ),
  ),
];
