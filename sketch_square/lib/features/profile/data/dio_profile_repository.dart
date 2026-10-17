import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/user.dart';
import '../domain/profile_repository.dart';

class DioProfileRepository implements ProfileRepository {
  DioProfileRepository(this._dio, {Dio? storageDio})
    : _storage = storageDio ?? Dio();

  final Dio _dio;

  /// Bare client for the presigned PUT: no bearer token to the storage host.
  final Dio _storage;

  @override
  Future<User> updateContact({String? phone, String? city}) async {
    try {
      final res = await _dio.patch<Object?>(
        '/me',
        data: {
          if (phone != null) 'phone': phone,
          if (city != null) 'city': city,
        },
      );
      return User.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<User> uploadAvatar(AvatarImage image) async {
    try {
      final target = await _dio.post<Object?>(
        '/me/avatar/upload-url',
        data: {'contentType': image.contentType},
      );
      final json = target.data! as Map<String, dynamic>;
      await _storage.put<void>(
        json['uploadUrl'] as String,
        data: image.bytes,
        options: Options(contentType: image.contentType),
      );
      final done = await _dio.post<Object?>(
        '/me/avatar/confirm',
        data: {'objectKey': json['objectKey']},
      );
      return User.fromJson(done.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class FilePickerAvatarPicker implements AvatarPicker {
  const FilePickerAvatarPicker();

  @override
  Future<AvatarImage?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AvatarImage.allowedExtensions,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    final type = AvatarImage.contentTypeForExtension(file.name);
    if (type == null) {
      throw const ApiException(
        code: ApiErrorCodes.validation,
        message: 'Choose a JPG, PNG or WebP image.',
      );
    }
    if (bytes.length > AvatarImage.maxBytes) {
      throw const ApiException(
        code: ApiErrorCodes.validation,
        message: 'Image is too large (max 5 MB).',
      );
    }
    return AvatarImage(bytes: bytes, contentType: type);
  }
}
