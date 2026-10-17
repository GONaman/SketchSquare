import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/auth/domain/auth_state.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';

const _architect = {
  'id': 'a1',
  'fullName': 'Asha Rao',
  'city': 'Bengaluru',
  'architectRating': 4,
  'ratingCount': 7,
  'avatarUrl': null,
};

void main() {
  test('User parses the contract shape', () {
    final user = User.fromJson({
      'id': 'u1',
      'email': 'a@b.co',
      'fullName': 'Asha Rao',
      'address': 'MG Road',
      'phone': '+9100',
      'avatarUrl': null,
      'city': 'Bengaluru',
      'role': 'ADMIN',
      'verificationStatus': 'PENDING',
      'architectRating': 4.5,
      'freeDownloadsUsed': 3,
      'freeDownloadLimit': 20,
      'createdAt': '2026-01-02T03:04:05.000Z',
    });
    expect(user.role, UserRole.admin);
    expect(user.verificationStatus, VerificationStatus.pending);
    expect(user.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(User.fromJson(user.toJson()), user);
  });

  test('DrawingSummary parses ints as doubles and optional sizeMatch', () {
    final json = {
      'id': 'd1',
      'title': '30x40 house',
      'category': {'id': 'c1', 'name': 'Houses', 'slug': 'houses'},
      'city': 'Jaipur',
      'plotLengthFt': 40,
      'plotBreadthFt': 30.5,
      'plotAreaSqft': 1220,
      'floors': 2,
      'facing': null,
      'pricePaise': 49900,
      'isFree': false,
      'avgRating': 4,
      'ratingCount': 2,
      'previewUrl': null,
      'architect': _architect,
      'status': 'UNDER_REVIEW',
      'createdAt': '2026-01-02T03:04:05.000Z',
    };
    final d = DrawingSummary.fromJson(json);
    expect(d.plotLengthFt, 40.0);
    expect(d.pricePaise, 49900);
    expect(d.status, DrawingStatus.underReview);
    expect(d.sizeMatch, isNull);
    expect(d.architect.architectRating, 4.0);

    expect(DrawingSummary.fromJson({...json, 'sizeMatch': 1}).sizeMatch, 1.0);
  });

  test('CursorPage parses items and nextCursor', () {
    final page = CursorPage.fromJson({
      'items': [_architect],
      'nextCursor': 'abc',
    }, (j) => j['id'] as String);
    expect(page.items, ['a1']);
    expect(page.hasMore, isTrue);

    final last = CursorPage.fromJson({
      'items': [],
      'nextCursor': null,
    }, (j) => j['id'] as String);
    expect(last.items, isEmpty);
    expect(last.hasMore, isFalse);
  });

  group('authRedirect', () {
    User withStatus(VerificationStatus s) =>
        stubUser.copyWith(verificationStatus: s);

    test('logged out goes to sign-in', () {
      const auth = AuthState.unauthenticated();
      expect(authRedirect(auth, AppRoutes.home), AppRoutes.signIn);
      expect(authRedirect(auth, AppRoutes.signIn), isNull);
    });

    test('unapproved users are pinned to the pending screen', () {
      for (final s in [
        VerificationStatus.pending,
        VerificationStatus.rejected,
      ]) {
        final auth = AuthState.authenticated(user: withStatus(s));
        expect(
          authRedirect(auth, AppRoutes.home),
          AppRoutes.verificationPending,
        );
        expect(authRedirect(auth, AppRoutes.verificationPending), isNull);
      }
    });

    test('approved users skip auth screens and keep other routes', () {
      final auth = AuthState.authenticated(
        user: withStatus(VerificationStatus.approved),
      );
      expect(authRedirect(auth, AppRoutes.signIn), AppRoutes.home);
      expect(authRedirect(auth, AppRoutes.verificationPending), AppRoutes.home);
      expect(authRedirect(auth, AppRoutes.basket), isNull);
    });
  });
}
