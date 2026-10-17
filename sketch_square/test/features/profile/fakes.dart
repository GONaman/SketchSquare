import 'dart:typed_data';

import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/profile/domain/profile_repository.dart';

import '../../helpers/fake_auth_repository.dart';

/// Applies edits to the [FakeAuthRepository] user, so `refreshUser()` (which
/// re-reads `/me`) sees what the real backend would return.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.auth);

  final FakeAuthRepository auth;
  ApiException? error;
  final contactCalls = <({String? phone, String? city})>[];
  final avatars = <AvatarImage>[];

  @override
  Future<User> updateContact({String? phone, String? city}) async {
    contactCalls.add((phone: phone, city: city));
    if (error != null) throw error!;
    auth.user = auth.user.copyWith(
      phone: phone ?? auth.user.phone,
      city: city ?? auth.user.city,
    );
    return auth.user;
  }

  @override
  Future<User> uploadAvatar(AvatarImage image) async {
    if (error != null) throw error!;
    avatars.add(image);
    auth.user = auth.user.copyWith(avatarUrl: 'https://cdn.test/avatar.png');
    return auth.user;
  }
}

class FakeAvatarPicker implements AvatarPicker {
  FakeAvatarPicker({this.image, this.error});

  AvatarImage? image;
  ApiException? error;

  @override
  Future<AvatarImage?> pick() async {
    if (error != null) throw error!;
    return image;
  }
}

AvatarImage fakeAvatar() =>
    AvatarImage(bytes: Uint8List.fromList([1, 2, 3]), contentType: 'image/png');
