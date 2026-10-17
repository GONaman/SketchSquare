import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import 'upload_screen.dart';

/// Routes of the Upload tab; registered as one branch in `core/router/app_router.dart`.
final uploadRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.upload,
    builder: (_, __) => const UploadScreen(),
    routes: [placeholderDetailRoute],
  ),
];
