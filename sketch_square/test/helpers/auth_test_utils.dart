import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/verification/presentation/verification_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_verification.dart';
import 'pump_app.dart';

/// Taller than the default 800x600 so long forms don't need scrolling.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Pumps the logged-out app with shared fakes; returns them for assertions.
Future<({FakeAuthRepository auth, FakeVerificationRepository verification})>
pumpLoggedOut(
  WidgetTester tester, {
  bool introSeen = true,
  List<Override> overrides = const [],
  FakeAuthRepository? auth,
  FakeVerificationRepository? verification,
  FakeDocumentPicker? picker,
}) async {
  useTallScreen(tester);
  final authRepo = auth ?? FakeAuthRepository();
  final verificationRepo = verification ?? FakeVerificationRepository();
  await pumpApp(
    tester,
    signedIn: false,
    introSeen: introSeen,
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      verificationRepositoryProvider.overrideWithValue(verificationRepo),
      documentPickerProvider.overrideWithValue(picker ?? FakeDocumentPicker()),
      ...overrides,
    ],
  );
  return (auth: authRepo, verification: verificationRepo);
}
