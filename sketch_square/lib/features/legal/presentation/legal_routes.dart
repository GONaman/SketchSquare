import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import 'legal_screen.dart';

/// Top-level so they open above the shell and work logged out (sign-up) or in
/// (settings).
final legalRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.terms,
    builder: (_, __) => const LegalDocumentScreen.terms(),
  ),
  GoRoute(
    path: AppRoutes.privacy,
    builder: (_, __) => const LegalDocumentScreen.privacy(),
  ),
];
