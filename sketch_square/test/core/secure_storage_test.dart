import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';

void main() {
  group('InMemorySecureStorage', () {
    test('write/read/delete/deleteAll', () async {
      final s = InMemorySecureStorage();
      expect(await s.read('k'), isNull);
      await s.write('k', 'v');
      await s.write('k2', 'v2');
      expect(await s.read('k'), 'v');
      await s.delete('k');
      expect(await s.read('k'), isNull);
      expect(await s.read('k2'), 'v2');
      await s.deleteAll();
      expect(await s.read('k2'), isNull);
    });

    test('initial data is copied', () async {
      final seed = {'a': '1'};
      final s = InMemorySecureStorage(seed);
      await s.write('b', '2');
      expect(seed.containsKey('b'), isFalse);
      expect(await s.read('a'), '1');
    });
  });

  group('SecureTokenStore', () {
    test('round-trips and clears tokens', () async {
      final store = SecureTokenStore(InMemorySecureStorage());
      expect(await store.read(), isNull);
      const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');
      await store.save(tokens);
      expect(await store.read(), tokens);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('returns null when only one token is present', () async {
      final storage = InMemorySecureStorage({SecureTokenStore.accessKey: 'a'});
      expect(await SecureTokenStore(storage).read(), isNull);
    });
  });
}
