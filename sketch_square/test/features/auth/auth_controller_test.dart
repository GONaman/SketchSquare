import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/auth/domain/auth_state.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/auth/presentation/intro_seen_provider.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late InMemorySecureStorage storage;
  late SecureTokenStore tokens;
  late FakeAuthRepository repo;

  Future<ProviderContainer> container({bool withTokens = false}) async {
    SharedPreferences.setMockInitialValues({});
    storage = InMemorySecureStorage();
    tokens = SecureTokenStore(storage);
    if (withTokens) {
      await tokens.save(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    }
    repo = FakeAuthRepository();
    final c = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<AuthState> settled(ProviderContainer c) async {
    expect(c.read(authControllerProvider), isA<Initializing>());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c.read(authControllerProvider);
  }

  test('no stored tokens -> unauthenticated, /me not called', () async {
    final c = await container();
    expect(await settled(c), isA<Unauthenticated>());
    expect(repo.calls, isEmpty);
  });

  test('stored tokens + /me ok -> authenticated', () async {
    final c = await container(withTokens: true);
    final s = await settled(c);
    expect(s, isA<Authenticated>());
    expect((s as Authenticated).user.id, stubUser.id);
  });

  test('stored tokens + /me failure -> unauthenticated, tokens kept', () async {
    final c = await container(withTokens: true);
    repo.errors['me'] = const ApiException(
      code: ApiErrorCodes.network,
      message: 'offline',
    );
    expect(await settled(c), isA<Unauthenticated>());
    expect(await tokens.read(), isNotNull);
  });

  test('signIn persists tokens, marks intro seen, authenticates', () async {
    final c = await container();
    await settled(c);
    await c
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.co', password: 'pw');

    expect(c.read(authControllerProvider), isA<Authenticated>());
    expect(
      await tokens.read(),
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    expect(c.read(introSeenProvider), isTrue);
    expect(
      c.read(sharedPreferencesProvider).getBool(IntroSeen.prefsKey),
      isTrue,
    );
  });

  test('failed signIn throws ApiException and stays logged out', () async {
    final c = await container();
    await settled(c);
    repo.errors['login'] = const ApiException(
      code: ApiErrorCodes.unauthorized,
      message: 'Invalid credentials',
      statusCode: 401,
    );
    await expectLater(
      c
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.co', password: 'bad'),
      throwsA(isA<ApiException>()),
    );
    expect(c.read(authControllerProvider), isA<Unauthenticated>());
    expect(await tokens.read(), isNull);
    expect(c.read(introSeenProvider), isFalse);
  });

  test('signUp authenticates as a PENDING architect', () async {
    final c = await container();
    await settled(c);
    await c
        .read(authControllerProvider.notifier)
        .signUp(
          email: 'n@b.co',
          password: 'password1',
          fullName: 'New Arch',
          phone: '+919999999999',
          address: 'Somewhere',
          city: 'Jaipur',
        );
    final s = c.read(authControllerProvider) as Authenticated;
    expect(s.user.verificationStatus, VerificationStatus.pending);
    expect(await tokens.read(), isNotNull);
  });

  test(
    'signOut clears tokens, revokes server side, ignores failures',
    () async {
      final c = await container(withTokens: true);
      await settled(c);
      repo.errors['logout'] = const ApiException(
        code: ApiErrorCodes.network,
        message: 'offline',
      );
      await c.read(authControllerProvider.notifier).signOut();
      expect(c.read(authControllerProvider), isA<Unauthenticated>());
      expect(await tokens.read(), isNull);
      expect(repo.calls, contains('logout'));
    },
  );

  test('session expiry from the HTTP layer logs the user out', () async {
    final c = await container(withTokens: true);
    expect(await settled(c), isA<Authenticated>());
    c.read(sessionExpiredProvider.notifier).notify();
    expect(c.read(authControllerProvider), isA<Unauthenticated>());
  });

  test('refreshUser re-reads /me', () async {
    final c = await container(withTokens: true);
    await settled(c);
    repo.user = repo.user.copyWith(
      verificationStatus: VerificationStatus.rejected,
    );
    await c.read(authControllerProvider.notifier).refreshUser();
    expect(
      (c.read(authControllerProvider) as Authenticated).user.verificationStatus,
      VerificationStatus.rejected,
    );
  });
}
