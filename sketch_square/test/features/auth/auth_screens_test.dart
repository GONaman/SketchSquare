import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/presentation/intro_seen_provider.dart';
import 'package:sketch_square/features/auth/presentation/intro_video_provider.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';

import '../../helpers/auth_test_utils.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_verification.dart';

final _fakeVideo = introVideoBuilderProvider.overrideWithValue(
  (context, muted) =>
      Center(child: Text(muted ? 'video muted' : 'video sound on')),
);

Future<void> _fillDetails(WidgetTester tester) async {
  await tester.enterText(field('Full name'), 'Asha Rao');
  await tester.enterText(field('Email'), 'asha@example.com');
  await tester.enterText(field('Phone'), '+91 98765 43210');
  await tester.enterText(field('Office address'), '12 MG Road');
  await tester.enterText(field('City'), 'Bengaluru');
  await tester.enterText(field('Password'), 'password1');
  await tester.enterText(field('Confirm password'), 'password1');
}

void main() {
  group('intro', () {
    testWidgets('first run shows the intro; Skip appears after 3 s', (
      tester,
    ) async {
      await pumpLoggedOut(tester, introSeen: false, overrides: [_fakeVideo]);

      expect(find.text('video muted'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('tap toggles mute', (tester) async {
      await pumpLoggedOut(tester, introSeen: false, overrides: [_fakeVideo]);
      await tester.tap(find.byTooltip('Unmute'));
      await tester.pump();
      expect(find.text('video sound on'), findsOneWidget);
    });

    testWidgets('Skip remembers the intro and opens sign-in', (tester) async {
      await pumpLoggedOut(tester, introSeen: false, overrides: [_fakeVideo]);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        ).read(introSeenProvider),
        isTrue,
      );
    });

    testWidgets('Create account goes to sign-up', (tester) async {
      await pumpLoggedOut(tester, introSeen: false, overrides: [_fakeVideo]);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Your details'), findsOneWidget);
    });

    testWidgets('once seen, logged-out users go straight to sign-in', (
      tester,
    ) async {
      await pumpLoggedOut(tester, introSeen: true, overrides: [_fakeVideo]);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('sign in', () {
    testWidgets('validates before calling the API', (tester) async {
      final r = await pumpLoggedOut(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(r.auth.calls, isNot(contains('login')));
    });

    testWidgets('success enters the app', (tester) async {
      final r = await pumpLoggedOut(tester);
      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.enterText(field('Password'), 'password1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(r.auth.calls, contains('login'));
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('wrong credentials show the server message inline', (
      tester,
    ) async {
      final auth =
          FakeAuthRepository()
            ..errors['login'] = const ApiException(
              code: ApiErrorCodes.unauthorized,
              message: 'Invalid email or password',
              statusCode: 401,
            );
      await pumpLoggedOut(tester, auth: auth);
      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.enterText(field('Password'), 'nope');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('links to forgot password and sign up', (tester) async {
      await pumpLoggedOut(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Send reset link'), findsOneWidget);
    });
  });

  group('sign up', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
    }

    testWidgets('step 1 validates every field', (tester) async {
      await pumpLoggedOut(tester);
      await openSignUp(tester);
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(find.text('Enter your full address'), findsOneWidget);
      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Enter a password'), findsOneWidget);
      expect(find.text('Your details'), findsOneWidget);
    });

    testWidgets('password mismatch is reported', (tester) async {
      await pumpLoggedOut(tester);
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.enterText(field('Confirm password'), 'different1');
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('step 2 requires a valid COA number and a document', (
      tester,
    ) async {
      final r = await pumpLoggedOut(tester);
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Verify you are an architect'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();
      expect(find.text('Enter your COA registration number'), findsOneWidget);
      expect(find.text('Attach your COA certificate or ID.'), findsOneWidget);
      expect(r.auth.calls, isEmpty);
    });

    testWidgets('happy path: account, upload, then verification pending', (
      tester,
    ) async {
      final r = await pumpLoggedOut(tester);
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(field('COA registration number'), 'CA/2015/12345');
      await tester.tap(find.textContaining('Attach COA certificate'));
      await tester.pumpAndSettle();
      expect(find.text('coa.pdf'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(r.auth.calls, contains('signup'));
      expect(r.auth.user.phone, '+919876543210');
      expect(r.verification.submissions.single.coa, 'CA/2015/12345');
      expect(find.text('Verification pending'), findsWidgets);
    });

    testWidgets('taken email sends the user back to step 1 with the error', (
      tester,
    ) async {
      final auth =
          FakeAuthRepository()
            ..errors['signup'] = const ApiException(
              code: ApiErrorCodes.conflict,
              message: 'Email already registered',
              statusCode: 409,
            );
      final r = await pumpLoggedOut(tester, auth: auth);
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(field('COA registration number'), 'CA/2015/12345');
      await tester.tap(find.textContaining('Attach COA certificate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Your details'), findsOneWidget);
      expect(find.text('Email already registered'), findsOneWidget);
      expect(r.verification.submissions, isEmpty);
    });

    testWidgets('upload failure keeps the account and offers retry/skip', (
      tester,
    ) async {
      final verification =
          FakeVerificationRepository()
            ..submitError = const ApiException(
              code: ApiErrorCodes.uploadInvalid,
              message: 'Unsupported file',
              statusCode: 400,
            );
      final r = await pumpLoggedOut(tester, verification: verification);
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(field('COA registration number'), 'CA/2015/12345');
      await tester.tap(find.textContaining('Attach COA certificate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Unsupported file'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Upload document'),
        findsOneWidget,
      );
      expect(r.auth.calls.where((c) => c == 'signup'), hasLength(1));

      // Retry succeeds without creating the account twice.
      verification.submitError = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Upload document'));
      await tester.pumpAndSettle();
      expect(r.auth.calls.where((c) => c == 'signup'), hasLength(1));
      expect(verification.submissions, hasLength(1));
      expect(find.text('Verification pending'), findsWidgets);
    });

    testWidgets('an invalid document is rejected client-side', (tester) async {
      await pumpLoggedOut(
        tester,
        picker: FakeDocumentPicker(
          VerificationDocument(
            fileName: 'plan.dwg',
            bytes: Uint8List.fromList([1]),
          ),
        ),
      );
      await openSignUp(tester);
      await _fillDetails(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Attach COA certificate'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a PDF, JPG or PNG file.'), findsOneWidget);
    });
  });

  group('forgot / reset password', () {
    testWidgets('forgot shows a neutral confirmation', (tester) async {
      final r = await pumpLoggedOut(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send reset link'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);

      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(r.auth.calls, contains('forgotPassword'));
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('asha@example.com'), findsOneWidget);
    });

    testWidgets('reset with code updates the password and returns to sign-in', (
      tester,
    ) async {
      final r = await pumpLoggedOut(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I have a reset code'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Reset code'), 'tok123');
      await tester.enterText(field('New password'), 'newpassword1');
      await tester.enterText(field('Confirm new password'), 'newpassword1');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(r.auth.calls, contains('resetPassword'));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Password updated. Please sign in.'), findsOneWidget);
    });

    testWidgets('an invalid or expired token shows the server error', (
      tester,
    ) async {
      final auth =
          FakeAuthRepository()
            ..errors['resetPassword'] = const ApiException(
              code: ApiErrorCodes.validation,
              message: 'Reset link is invalid or expired',
              statusCode: 400,
            );
      await pumpLoggedOut(tester, auth: auth);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), 'asha@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I have a reset code'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Reset code'), 'bad');
      await tester.enterText(field('New password'), 'newpassword1');
      await tester.enterText(field('Confirm new password'), 'newpassword1');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('reset code is invalid or has expired'),
        findsOneWidget,
      );
    });
  });
}
