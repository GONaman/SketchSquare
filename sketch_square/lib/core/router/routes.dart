import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/domain/user.dart';

abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const verificationPending = '/verification-pending';
  static const home = '/home';
  static const featured = '/featured';
  static const upload = '/upload';
  static const basket = '/basket';
  static const profile = '/profile';

  /// Sub-route segment registered under every tab, for per-tab stack tests.
  static const detailSegment = 'details';
}

/// Pure redirect rules for the router guard. Returns null to stay put.
String? authRedirect(AuthState auth, String location) {
  switch (auth) {
    case Unauthenticated():
      return location == AppRoutes.signIn ? null : AppRoutes.signIn;
    case Authenticated(:final user):
      if (user.verificationStatus != VerificationStatus.approved) {
        return location == AppRoutes.verificationPending
            ? null
            : AppRoutes.verificationPending;
      }
      if (location == AppRoutes.signIn ||
          location == AppRoutes.verificationPending) {
        return AppRoutes.home;
      }
      return null;
  }
}
