import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/architect_profile.dart';
import '../domain/architects_repository.dart';
import 'dio_architects_repository.dart';

part 'architects_providers.g.dart';

@Riverpod(keepAlive: true)
ArchitectsRepository architectsRepository(Ref ref) =>
    DioArchitectsRepository(ref.watch(dioProvider));

@riverpod
Future<List<TopArchitect>> topArchitects(Ref ref, String? city) =>
    ref.watch(architectsRepositoryProvider).top(city: city);
