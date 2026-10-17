import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../data/dio_auth_repository.dart';
import '../domain/auth_repository.dart';

part 'auth_repository_provider.g.dart';

/// Screens and controllers depend on the interface; tests override this.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    DioAuthRepository(ref.watch(dioProvider));
