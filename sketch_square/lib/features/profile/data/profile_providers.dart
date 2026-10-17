import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../architects/data/architects_providers.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../domain/profile_repository.dart';
import 'dio_profile_repository.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    DioProfileRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
AvatarPicker avatarPicker(Ref ref) => const FilePickerAvatarPicker();

/// Public stats of the signed-in architect (`GET /architects/:id`).
@riverpod
Future<ProfileStats> profileStats(Ref ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) {
    return const ProfileStats(rating: 0, ratingCount: 0, publishedDrawings: 0);
  }
  final profile = await ref
      .watch(architectsRepositoryProvider)
      .getArchitect(id);
  return ProfileStats(
    rating: profile.architect.architectRating,
    ratingCount: profile.architect.ratingCount,
    publishedDrawings: profile.drawings.items.length,
    hasMoreDrawings: profile.drawings.hasMore,
  );
}
