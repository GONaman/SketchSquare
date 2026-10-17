import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/auth/domain/auth_state.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/legal/presentation/legal_content.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('authRedirect for legal routes', () {
    final pending = AuthState.authenticated(
      user: User(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'A',
        address: 'x',
        phone: '+911234567890',
        city: 'Pune',
        role: UserRole.architect,
        verificationStatus: VerificationStatus.pending,
        createdAt: DateTime(2026),
      ),
    );

    test('are reachable logged out and while verification is pending', () {
      for (final path in AppRoutes.legalRoutes) {
        expect(authRedirect(const AuthState.unauthenticated(), path), isNull);
        expect(authRedirect(pending, path), isNull);
      }
    });

    test('wait for the session to initialise', () {
      expect(
        authRedirect(const AuthState.initializing(), AppRoutes.terms),
        AppRoutes.splash,
      );
    });
  });

  test('terms cover the licence and the privacy policy is non-empty', () {
    final terms = LegalContent.terms.map((s) => s.body).join(' ');
    expect(terms, contains('non-exclusive'));
    expect(terms, contains('resell'));
    expect(terms, contains('re-upload'));
    expect(LegalContent.privacy, isNotEmpty);
  });

  group('screens', () {
    testWidgets('sign-up links to the terms and the privacy policy', (
      tester,
    ) async {
      final c = await pumpApp(tester, signedIn: false);
      c.read(appRouterProvider).go(AppRoutes.signUp);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('link-terms')));
      await tester.tap(find.byKey(const Key('link-terms')));
      await tester.pumpAndSettle();
      expect(inAppBar(LegalContent.termsTitle), findsOneWidget);
      expect(find.textContaining('non-exclusive'), findsOneWidget);

      c.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('link-privacy')));
      await tester.tap(find.byKey(const Key('link-privacy')));
      await tester.pumpAndSettle();
      expect(inAppBar(LegalContent.privacyTitle), findsOneWidget);
    });

    testWidgets('settings links to both documents', (tester) async {
      final c = await pumpApp(tester);
      c.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-terms')));
      await tester.pumpAndSettle();
      expect(inAppBar(LegalContent.termsTitle), findsOneWidget);
    });
  });
}
