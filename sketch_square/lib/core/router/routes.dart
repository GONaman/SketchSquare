import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/user.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const intro = '/intro';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verificationPending = '/verification-pending';
  static const admin = '/admin';
  static const home = '/home';
  static const featured = '/featured';
  static const upload = '/upload';
  static const basket = '/basket';
  static const profile = '/profile';

  static const basketCheckout = '/basket/checkout';
  static const basketOrderResult = '/basket/order-result';
  static const purchases = '/profile/purchases';

  /// Sub-route segment registered under every tab, for per-tab stack tests.
  static const detailSegment = 'details';

  /// Screens a logged-out user may see.
  static const publicRoutes = {
    intro,
    signIn,
    signUp,
    forgotPassword,
    resetPassword,
  };
}

/// Pure redirect rules for the router guard. Returns null to stay put.
/// [introSeen] decides whether logged-out users land on the intro video or
/// straight on sign-in.
String? authRedirect(AuthState auth, String location, {bool introSeen = true}) {
  switch (auth) {
    case Initializing():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case Unauthenticated():
      if (AppRoutes.publicRoutes.contains(location)) return null;
      return introSeen ? AppRoutes.signIn : AppRoutes.intro;
    case Authenticated(:final user):
      if (user.verificationStatus != VerificationStatus.approved) {
        // Sign-up stays reachable so the "upload your document" step can finish
        // right after the account is created.
        return location == AppRoutes.verificationPending ||
                location == AppRoutes.signUp
            ? null
            : AppRoutes.verificationPending;
      }
      if (_isAdminRoute(location) && user.role != UserRole.admin) {
        return AppRoutes.home;
      }
      if (AppRoutes.publicRoutes.contains(location) ||
          location == AppRoutes.splash ||
          location == AppRoutes.verificationPending) {
        return AppRoutes.home;
      }
      return null;
  }
}

bool _isAdminRoute(String location) =>
    location == AppRoutes.admin || location.startsWith('${AppRoutes.admin}/');
