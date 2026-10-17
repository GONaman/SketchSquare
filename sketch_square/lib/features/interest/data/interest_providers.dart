import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/interest_repository.dart';
import 'dio_interest_repository.dart';

part 'interest_providers.g.dart';

@Riverpod(keepAlive: true)
InterestRepository interestRepository(Ref ref) =>
    DioInterestRepository(ref.watch(dioProvider));
