import 'dart:typed_data';

import '../../auth/domain/user.dart';

/// An image chosen for the avatar.
class AvatarImage {
  const AvatarImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;

  static const maxBytes = 5 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static String? contentTypeForExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}

abstract interface class ProfileRepository {
  /// `PATCH /me`. Only phone and city are editable (name/address are fixed
  /// by the verification record).
  Future<User> updateContact({String? phone, String? city});

  /// `POST /me/avatar/upload-url` → PUT to storage → `POST /me/avatar/confirm`.
  Future<User> uploadAvatar(AvatarImage image);
}

abstract interface class AvatarPicker {
  /// Null when the user cancelled. Throws `ApiException` for a bad file.
  Future<AvatarImage?> pick();
}

/// Public numbers shown on the profile header.
class ProfileStats {
  const ProfileStats({
    required this.rating,
    required this.ratingCount,
    required this.publishedDrawings,
    this.hasMoreDrawings = false,
  });

  final double rating;
  final int ratingCount;
  final int publishedDrawings;

  /// True when the first page was full, so [publishedDrawings] is a lower bound.
  final bool hasMoreDrawings;

  String get drawingsLabel =>
      hasMoreDrawings ? '$publishedDrawings+' : '$publishedDrawings';
}
