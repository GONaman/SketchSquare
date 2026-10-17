import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';
import 'package:sketch_square/features/verification/presentation/verification_providers.dart';

import '../../helpers/auth_test_utils.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_verification.dart';
import '../../helpers/pump_app.dart';

VerificationRequest _request(VerificationStatus status, {String? note}) =>
    VerificationRequest(
      id: 'v1',
      coaRegistrationNumber: 'CA/2015/12345',
      status: status,
      reviewNote: note,
      submittedAt: DateTime.utc(2026, 1, 2),
      reviewedAt: note == null ? null : DateTime.utc(2026, 1, 3),
    );

Future<({FakeAuthRepository auth, FakeVerificationRepository verification})>
_pump(
  WidgetTester tester, {
  required VerificationStatus status,
  VerificationRequest? request,
}) async {
  useTallScreen(tester);
  final auth = FakeAuthRepository(
    user: stubUser.copyWith(verificationStatus: status),
  );
  final verification = FakeVerificationRepository(current: request);
  await pumpApp(
    tester,
    user: auth.user,
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      verificationRepositoryProvider.overrideWithValue(verification),
    ],
  );
  return (auth: auth, verification: verification);
}

void main() {
  testWidgets('pending: status, COA number, submitted date, 24h promise', (
    tester,
  ) async {
    await _pump(
      tester,
      status: VerificationStatus.pending,
      request: _request(VerificationStatus.pending),
    );
    expect(inAppBar('Verification pending'), findsOneWidget);
    expect(find.text("We'll email you within 24 hours."), findsOneWidget);
    expect(find.text('CA/2015/12345'), findsOneWidget);
    expect(find.text('Jan 2, 2026'), findsOneWidget);
    expect(find.text('Resubmit for review'), findsNothing);
    expect(find.text('Wrong document? Replace it'), findsOneWidget);
  });

  testWidgets('rejected: shows the reason and a prefilled resubmit form', (
    tester,
  ) async {
    await _pump(
      tester,
      status: VerificationStatus.rejected,
      request: _request(VerificationStatus.rejected, note: 'Blurry scan'),
    );
    expect(inAppBar('Verification rejected'), findsOneWidget);
    expect(find.text('Blurry scan'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(field('COA registration number'))
          .controller
          ?.text,
      'CA/2015/12345',
    );
  });

  testWidgets('resubmitting uploads the document and flips to pending', (
    tester,
  ) async {
    final r = await _pump(
      tester,
      status: VerificationStatus.rejected,
      request: _request(VerificationStatus.rejected, note: 'Blurry scan'),
    );
    await tester.tap(find.textContaining('Attach COA certificate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resubmit for review'));
    await tester.pumpAndSettle();

    expect(r.verification.submissions.single.coa, 'CA/2015/12345');
    expect(r.auth.calls, contains('me'));
    expect(inAppBar('Verification pending'), findsOneWidget);
    expect(find.text('Blurry scan'), findsNothing);
    expect(find.text('Submitted. We will review it shortly.'), findsOneWidget);
  });

  testWidgets('a failed resubmission keeps the form and shows the error', (
    tester,
  ) async {
    final r = await _pump(
      tester,
      status: VerificationStatus.rejected,
      request: _request(VerificationStatus.rejected, note: 'Blurry scan'),
    );
    r.verification.submitError = const ApiException(
      code: ApiErrorCodes.uploadInvalid,
      message: 'Unsupported file',
    );
    await tester.tap(find.textContaining('Attach COA certificate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resubmit for review'));
    await tester.pumpAndSettle();

    expect(find.text('Unsupported file'), findsOneWidget);
    expect(inAppBar('Verification rejected'), findsOneWidget);
  });

  testWidgets('no request on file: upload form', (tester) async {
    final r = await _pump(tester, status: VerificationStatus.pending);
    expect(find.text('Submit your documents'), findsOneWidget);

    await tester.enterText(field('COA registration number'), 'CA/2020/777');
    await tester.tap(find.textContaining('Attach COA certificate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(r.verification.submissions.single.coa, 'CA/2020/777');
    expect(find.text('CA/2020/777'), findsOneWidget);
  });

  testWidgets('refresh picks up an approval and enters the app', (
    tester,
  ) async {
    final r = await _pump(
      tester,
      status: VerificationStatus.pending,
      request: _request(VerificationStatus.pending),
    );
    expect(find.byType(NavigationBar), findsNothing);

    r.auth.user = r.auth.user.copyWith(
      verificationStatus: VerificationStatus.approved,
    );
    await tester.tap(find.byTooltip('Refresh status'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('refresh failure is shown inline', (tester) async {
    final r = await _pump(
      tester,
      status: VerificationStatus.pending,
      request: _request(VerificationStatus.pending),
    );
    r.auth.errors['me'] = const ApiException(
      code: ApiErrorCodes.network,
      message: 'You appear to be offline.',
    );
    await tester.tap(find.byTooltip('Refresh status'));
    await tester.pumpAndSettle();
    expect(find.text('You appear to be offline.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sign out returns to sign-in', (tester) async {
    await _pump(
      tester,
      status: VerificationStatus.pending,
      request: _request(VerificationStatus.pending),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(inAppBar('Sign in'), findsOneWidget);
  });
}
