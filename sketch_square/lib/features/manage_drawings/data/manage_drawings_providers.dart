import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/manage_drawings_repository.dart';
import 'dio_manage_drawings_repository.dart';

part 'manage_drawings_providers.g.dart';

@Riverpod(keepAlive: true)
ManageDrawingsRepository manageDrawingsRepository(Ref ref) =>
    DioManageDrawingsRepository(ref.watch(dioProvider));
