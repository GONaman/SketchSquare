import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/dio_plagiarism_repository.dart';
import '../domain/plagiarism_repository.dart';

final plagiarismRepositoryProvider = Provider<PlagiarismRepository>(
  (ref) => DioPlagiarismRepository(ref.watch(dioProvider)),
);
