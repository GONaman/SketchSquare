import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('approved session boots straight into the shell', (tester) async {
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(inAppBar('Home'), findsOneWidget);
  });

  testWidgets('no stored session lands on sign-in', (tester) async {
    await pumpApp(tester, signedIn: false);
    expect(find.byType(NavigationBar), findsNothing);
    expect(inAppBar('Sign in'), findsOneWidget);
  });

  for (final (status, title) in [
    (VerificationStatus.pending, 'Verification pending'),
    (VerificationStatus.rejected, 'Verification rejected'),
  ]) {
    testWidgets('$status user is pinned to the verification screen', (
      tester,
    ) async {
      await pumpApp(
        tester,
        user: stubUser.copyWith(verificationStatus: status),
      );
      expect(find.byType(NavigationBar), findsNothing);
      expect(inAppBar(title), findsOneWidget);
    });
  }

  testWidgets('session expiry drops the user back to sign-in', (tester) async {
    final container = await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    container.read(sessionExpiredProvider.notifier).notify();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(inAppBar('Sign in'), findsOneWidget);
  });
}
