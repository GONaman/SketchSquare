import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/profile/data/dio_profile_repository.dart';
import 'package:sketch_square/features/profile/domain/profile_repository.dart';

import '../../helpers/scripted_adapter.dart';
import 'fakes.dart';

const _userJson = {
  'id': 'u1',
  'email': 'a@b.co',
  'fullName': 'Asha Rao',
  'address': '1 Street',
  'phone': '+919999999999',
  'avatarUrl': 'https://cdn.test/a.png',
  'city': 'Pune',
  'role': 'ARCHITECT',
  'verificationStatus': 'APPROVED',
  'architectRating': 4.5,
  'freeDownloadsUsed': 1,
  'freeDownloadLimit': 20,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  Dio dio(ScriptedAdapter a) =>
      Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = a;

  test('updateContact PATCHes only the provided fields', () async {
    final a = ScriptedAdapter((_) => jsonResponse(_userJson));
    final repo = DioProfileRepository(dio(a));

    final user = await repo.updateContact(city: 'Pune');
    await repo.updateContact(phone: '+911234567890', city: 'Goa');

    expect(user.city, 'Pune');
    expect(a.requests[0].method, 'PATCH');
    expect(a.requests[0].path, '/me');
    expect(a.requests[0].data, {'city': 'Pune'});
    expect(a.requests[1].data, {'phone': '+911234567890', 'city': 'Goa'});
  });

  test('server validation errors surface as ApiException', () async {
    final a = ScriptedAdapter(
      (_) =>
          errorResponse(400, 'VALIDATION_ERROR', 'fullName cannot be changed'),
    );
    final repo = DioProfileRepository(dio(a));

    await expectLater(
      repo.updateContact(phone: '1'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR'),
      ),
    );
  });

  test(
    'uploadAvatar: upload-url -> PUT to storage (no API host) -> confirm',
    () async {
      final api = ScriptedAdapter((o) {
        if (o.path == '/me/avatar/upload-url') {
          return jsonResponse({
            'uploadUrl': 'https://storage.test/put?sig=1',
            'objectKey': 'avatars/u1.png',
          });
        }
        return jsonResponse(_userJson);
      });
      final storage = ScriptedAdapter((_) => jsonResponse(null, 200));
      final repo = DioProfileRepository(
        dio(api),
        storageDio: Dio()..httpClientAdapter = storage,
      );

      final user = await repo.uploadAvatar(fakeAvatar());

      expect(user.avatarUrl, 'https://cdn.test/a.png');
      expect(api.requests[0].data, {'contentType': 'image/png'});
      expect(storage.requests.single.method, 'PUT');
      expect(storage.requests.single.uri.host, 'storage.test');
      expect(storage.requests.single.headers['Content-Type'], 'image/png');
      expect(
        storage.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(api.requests[1].path, '/me/avatar/confirm');
      expect(api.requests[1].data, {'objectKey': 'avatars/u1.png'});
    },
  );

  test('avatar content types come from the extension', () {
    expect(AvatarImage.contentTypeForExtension('me.JPG'), 'image/jpeg');
    expect(AvatarImage.contentTypeForExtension('me.jpeg'), 'image/jpeg');
    expect(AvatarImage.contentTypeForExtension('me.png'), 'image/png');
    expect(AvatarImage.contentTypeForExtension('me.webp'), 'image/webp');
    expect(AvatarImage.contentTypeForExtension('me.gif'), isNull);
    expect(AvatarImage.contentTypeForExtension('noext'), isNull);
  });

  test('ProfileStats label marks a lower bound', () {
    const exact = ProfileStats(rating: 4, ratingCount: 3, publishedDrawings: 7);
    const more = ProfileStats(
      rating: 4,
      ratingCount: 3,
      publishedDrawings: 20,
      hasMoreDrawings: true,
    );
    expect(exact.drawingsLabel, '7');
    expect(more.drawingsLabel, '20+');
  });
}
