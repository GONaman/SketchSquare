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

  testWidgets('PENDING and REJECTED users are pinned to verification', (
    tester,
  ) async {
    for (final status in [
      VerificationStatus.pending,
      VerificationStatus.rejected,
    ]) {
      await pumpApp(
        tester,
        user: stubUser.copyWith(verificationStatus: status),
      );
      expect(find.byType(NavigationBar), findsNothing, reason: '$status');
      expect(inAppBar('Verification pending'), findsOneWidget);
    }
  });

  testWidgets('session expiry drops the user back to sign-in', (tester) async {
    final container = await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    container.read(sessionExpiredProvider.notifier).notify();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(inAppBar('Sign in'), findsOneWidget);
  });
}
