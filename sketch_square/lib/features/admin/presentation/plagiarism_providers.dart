import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/dio_plagiarism_repository.dart';
import '../domain/plagiarism_repository.dart';

final plagiarismRepositoryProvider = Provider<PlagiarismRepository>(
  (ref) => DioPlagiarismRepository(ref.watch(dioProvider)),
);

/// Size of the pending plagiarism queue (first page; [more] when truncated).
final pendingPlagiarismCountProvider =
    FutureProvider.autoDispose<({int count, bool more})>((ref) async {
      final page = await ref.watch(plagiarismRepositoryProvider).flags();
      return (count: page.items.length, more: page.hasMore);
    });
