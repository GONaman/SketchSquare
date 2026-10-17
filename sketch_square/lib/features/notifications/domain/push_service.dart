/// Source of this device's push token. This is the seam between the app and
/// a push provider: everything else (registering the token with the backend on
/// sign-in, removing it on sign-out, the in-app inbox) is already wired.
///
/// TODO(owner): to enable real push, add `firebase_core` + `firebase_messaging`,
/// drop `google-services.json` / `GoogleService-Info.plist` into the platform
/// projects (and set the backend's `FCM_*` env), then implement this interface
/// with `FirebaseMessaging.instance` (`getToken`, `onTokenRefresh`,
/// `deleteToken`) and override `pushServiceProvider` in `main.dart`. No other
/// code needs to change. Until then [NoopPushService] is used.
abstract interface class PushService {
  /// `android`, `ios` or `web`, as the backend expects in `platform`.
  String get platform;

  /// This device's current token, or null when push is unavailable/denied.
  Future<String?> getToken();

  /// Emits whenever the provider rotates the token.
  Stream<String> get onTokenRefresh;
}

/// Default implementation: push is not configured, so no token is ever
/// registered. The in-app notification list keeps working.
class NoopPushService implements PushService {
  const NoopPushService({this.platform = 'android'});

  @override
  final String platform;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}
