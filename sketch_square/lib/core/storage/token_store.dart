import 'secure_storage.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  bool operator ==(Object other) =>
      other is AuthTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);
}

abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  static const accessKey = 'auth.access_token';
  static const refreshKey = 'auth.refresh_token';

  final SecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(accessKey);
    final refresh = await _storage.read(refreshKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(accessKey, tokens.accessToken);
    await _storage.write(refreshKey, tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(accessKey);
    await _storage.delete(refreshKey);
  }
}
