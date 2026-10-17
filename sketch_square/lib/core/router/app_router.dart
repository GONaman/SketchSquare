import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_routes.dart';
import '../../features/auth/presentation/intro_seen_provider.dart';
import '../../features/basket/presentation/basket_routes.dart';
import '../../features/featured/presentation/featured_routes.dart';
import '../../features/home/presentation/home_routes.dart';
import '../../features/profile/presentation/profile_routes.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/upload/presentation/upload_routes.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Re-evaluates `redirect` whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(introSeenProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect:
        (context, state) => authRedirect(
          ref.read(authControllerProvider),
          state.matchedLocation,
          introSeen: ref.read(introSeenProvider),
        ),
    routes: [
      ...authRoutes,
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
