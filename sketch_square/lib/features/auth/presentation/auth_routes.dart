import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../verification/presentation/verification_status_screen.dart';
import 'forgot_password_screen.dart';
import 'intro_screen.dart';
import 'reset_password_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'splash_screen.dart';

/// Non-tab routes of the auth feature; spread into the top-level routes in
/// `core/router/app_router.dart`.
final authRoutes = <RouteBase>[
  GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
  GoRoute(path: AppRoutes.intro, builder: (_, __) => const IntroScreen()),
  GoRoute(path: AppRoutes.signIn, builder: (_, __) => const SignInScreen()),
  GoRoute(path: AppRoutes.signUp, builder: (_, __) => const SignUpScreen()),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (_, __) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.resetPassword,
    builder:
        (_, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
  ),
  GoRoute(
    path: AppRoutes.verificationPending,
    builder: (_, __) => const VerificationStatusScreen(),
  ),
];
