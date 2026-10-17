import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => createDio(tokenStore: ref.watch(tokenStoreProvider));
