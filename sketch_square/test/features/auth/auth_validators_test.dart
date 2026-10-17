import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/domain/auth_validators.dart';
import 'package:sketch_square/features/auth/presentation/widgets/form_widgets.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';

VerificationDocument doc(String name, [int size = 10]) => VerificationDocument(
  fileName: name,
  bytes: Uint8List(size)..fillRange(0, size, 1),
);

void main() {
  group('AuthValidators', () {
    test('email', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('nope'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
      expect(AuthValidators.email(' a@b.co '), isNull);
    });

    test('password needs 8+ chars; sign-in only requires presence', () {
      expect(AuthValidators.password('short'), isNotNull);
      expect(AuthValidators.password('longenough'), isNull);
      expect(AuthValidators.requiredPassword(''), isNotNull);
      expect(AuthValidators.requiredPassword('x'), isNull);
    });

    test('confirmPassword compares with the live value', () {
      var other = 'abc12345';
      final v = AuthValidators.confirmPassword(() => other);
      expect(v('abc12345'), isNull);
      other = 'changed!!';
      expect(v('abc12345'), isNotNull);
    });

    test('phone accepts separators and normalizes them away', () {
      expect(AuthValidators.phone('+91 98765-43210'), isNull);
      expect(AuthValidators.phone('12345'), isNotNull);
      expect(AuthValidators.phone(''), isNotNull);
      expect(AuthValidators.normalizePhone('+91 98765-43210'), '+919876543210');
    });

    test('name, address, city, reset token', () {
      expect(AuthValidators.fullName('A'), isNotNull);
      expect(AuthValidators.fullName('Asha Rao'), isNull);
      expect(AuthValidators.address('MG'), isNotNull);
      expect(AuthValidators.address('12 MG Road'), isNull);
      expect(AuthValidators.city(' '), isNotNull);
      expect(AuthValidators.city('Pune'), isNull);
      expect(AuthValidators.resetToken(' '), isNotNull);
      expect(AuthValidators.resetToken('abc'), isNull);
    });

    test('coaNumber', () {
      expect(AuthValidators.coaNumber(''), isNotNull);
      expect(AuthValidators.coaNumber('ab'), isNotNull);
      expect(AuthValidators.coaNumber('CA 2015'), isNotNull);
      expect(AuthValidators.coaNumber('CA/2015/12345'), isNull);
      expect(AuthValidators.coaNumber('CA-2015-12345'), isNull);
    });
  });

  group('VerificationDocument', () {
    test('mime type and extension', () {
      expect(doc('a.PDF').mimeType, 'application/pdf');
      expect(doc('a.png').mimeType, 'image/png');
      expect(doc('a.jpeg').mimeType, 'image/jpeg');
      expect(doc('a.jpg').extension, 'jpg');
      expect(doc('noext').mimeType, 'application/octet-stream');
    });

    test('problem flags bad type, empty and oversized files', () {
      expect(doc('a.pdf').problem, isNull);
      expect(doc('a.dwg').problem, isNotNull);
      expect(doc('a.pdf', 0).problem, isNotNull);
      expect(
        doc('a.pdf', VerificationDocument.maxBytes + 1).problem,
        isNotNull,
      );
      expect(doc('a.pdf', VerificationDocument.maxBytes).problem, isNull);
    });
  });

  group('serverFieldErrors', () {
    test('reads details.fields of a VALIDATION_ERROR', () {
      const e = ApiException(
        code: ApiErrorCodes.validation,
        message: 'bad',
        details: {
          'fields': {
            'email': ['taken', 'invalid'],
            'city': 'required',
          },
        },
      );
      expect(serverFieldErrors(e), {
        'email': 'taken\ninvalid',
        'city': 'required',
      });
    });

    test('is empty for other errors', () {
      const e = ApiException(code: ApiErrorCodes.conflict, message: 'x');
      expect(serverFieldErrors(e), isEmpty);
    });
  });
}
