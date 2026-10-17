import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/connectivity_status.dart';
import 'network/dio_client.dart';
import 'storage/secure_storage.dart';
import 'storage/token_store.dart';

part 'providers.g.dart';

/// Override with [InMemorySecureStorage] in tests.
@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) => FlutterSecureStorageImpl();

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) =>
    SecureTokenStore(ref.watch(secureStorageProvider));

/// Must be overridden in `main()` (after `SharedPreferences.getInstance()`) and
/// in tests (see `pumpApp`), so reads of simple flags stay synchronous.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('Override sharedPreferencesProvider');

/// Bumped when the HTTP layer gives up on the session (refresh token
/// rejected); the auth controller listens and signs the user out.
@Riverpod(keepAlive: true)
class SessionExpired extends _$SessionExpired {
  @override
  int build() => 0;

  void notify() => state++;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => createDio(
  tokenStore: ref.watch(tokenStoreProvider),
  onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).notify(),
  onConnectivityChanged: (online) {
    final status = ref.read(connectivityStatusProvider.notifier);
    online ? status.reportOnline() : status.reportOffline();
  },
);
