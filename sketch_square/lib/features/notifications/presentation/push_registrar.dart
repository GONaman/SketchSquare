import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/current_user_provider.dart';
import '../data/notifications_providers.dart';
import '../domain/notifications_repository.dart';
import '../domain/push_service.dart';

part 'push_registrar.g.dart';

/// Keeps the backend's device-token table in sync with this device: registers
/// the token on sign-in (and whenever it rotates) and removes it on sign-out.
/// Every call is best effort; push problems must never break the app.
class PushRegistrar {
  PushRegistrar(this._push, this._tokens);

  final PushService _push;
  final DeviceTokensRepository _tokens;
  String? _registered;
  StreamSubscription<String>? _refresh;

  String? get registeredToken => _registered;

  Future<void> register() async {
    try {
      final token = await _push.getToken();
      if (token != null) await _send(token);
      _refresh ??= _push.onTokenRefresh.listen((t) => unawaited(_send(t)));
    } catch (_) {}
  }

  Future<void> _send(String token) async {
    try {
      await _tokens.register(token, platform: _push.platform);
      _registered = token;
    } catch (_) {}
  }

  /// Call while the session is still valid (the endpoint needs auth).
  Future<void> unregister() async {
    unawaited(_refresh?.cancel());
    _refresh = null;
    final token = _registered;
    if (token == null) return;
    _registered = null;
    try {
      await _tokens.unregister(token);
    } catch (_) {}
  }

  void dispose() => unawaited(_refresh?.cancel());
}

@Riverpod(keepAlive: true)
PushRegistrar pushRegistrar(Ref ref) {
  final registrar = PushRegistrar(
    ref.watch(pushServiceProvider),
    ref.watch(deviceTokensRepositoryProvider),
  );
  ref.onDispose(registrar.dispose);
  return registrar;
}

/// Mounted once at the app root: registers the device token whenever a user
/// signs in. Sign-out is handled by `AuthController.signOut`, which must
/// unregister before the access token is cleared.
@Riverpod(keepAlive: true)
void pushRegistration(Ref ref) {
  final registrar = ref.watch(pushRegistrarProvider);
  void onUser(String? id) {
    if (id != null) unawaited(registrar.register());
  }

  onUser(ref.read(currentUserIdProvider));
  ref.listen(currentUserIdProvider, (_, id) => onUser(id));
}
