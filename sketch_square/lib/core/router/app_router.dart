import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/basket/presentation/basket_routes.dart';
import '../../features/featured/presentation/featured_routes.dart';
import '../../features/home/presentation/home_routes.dart';
import '../../features/profile/presentation/profile_routes.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/upload/presentation/upload_routes.dart';
import '../widgets/placeholder_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Re-evaluates `redirect` whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect:
        (context, state) => authRedirect(
          ref.read(authControllerProvider),
          state.matchedLocation,
        ),
    routes: [
      // Auth routes (Phase 2 replaces these placeholders).
      GoRoute(
        path: AppRoutes.signIn,
        builder:
            (_, __) =>
                const PlaceholderScreen(title: 'Sign in', icon: Icons.login),
      ),
      GoRoute(
        path: AppRoutes.verificationPending,
        builder:
            (_, __) => const PlaceholderScreen(
              title: 'Verification pending',
              icon: Icons.hourglass_empty,
            ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        // Branch order == bottom-nav order. Each feature owns its routes.
        branches: [
          StatefulShellBranch(routes: homeRoutes),
          StatefulShellBranch(routes: featuredRoutes),
          StatefulShellBranch(routes: uploadRoutes),
          StatefulShellBranch(routes: basketRoutes),
          StatefulShellBranch(routes: profileRoutes),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}
