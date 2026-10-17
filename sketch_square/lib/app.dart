import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/layout/layout.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'features/notifications/presentation/push_registrar.dart';

class SketchSquareApp extends ConsumerWidget {
  const SketchSquareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushRegistrationProvider);
    return MaterialApp.router(
      title: 'SketchSquare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(appThemeModeProvider),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(appRouterProvider),
      builder:
          (context, child) => FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: OfflineBanner(child: child!),
          ),
    );
  }
}
