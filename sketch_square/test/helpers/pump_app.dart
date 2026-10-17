import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch_square/app.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/core/widgets/brand_mark.dart';
import 'package:sketch_square/features/admin/presentation/admin_providers.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/features/auth/presentation/intro_seen_provider.dart';
import 'package:sketch_square/features/notifications/data/notifications_providers.dart';
import 'package:sketch_square/features/verification/presentation/verification_providers.dart';

import 'fake_admin.dart';
import 'fake_auth_repository.dart';
import 'fake_notifications.dart';
import 'fake_verification.dart';

/// Pumps the full app with test-safe overrides (no network font fetches, no
/// native secure storage, no real backend). Extra [overrides] win over the
/// defaults.
///
/// By default the app starts signed in as an approved architect (a fake
/// `AuthRepository` serves `/me`), so feature tests land on the shell. Pass
/// `signedIn: false` for the logged-out flow, or [user] to pick the session
/// user (e.g. a PENDING architect or an ADMIN). [introSeen] seeds the
/// onboarding flag.
///
/// Unless the test already picked a surface size (or passes [size]), the app
/// is pumped at a phone size (390x844) so the compact layout (bottom
/// `NavigationBar`) is what tests see; the flutter_test default of 800x600 would
/// otherwise select the tablet layout.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  bool signedIn = true,
  User? user,
  bool introSeen = true,
  Size? size,
}) async {
  AppTheme.useGoogleFonts = false;
  final untouched =
      tester.view.physicalSize == const Size(2400, 1800) &&
      tester.view.devicePixelRatio == 3;
  if (size != null || untouched) {
    tester.view.physicalSize = size ?? const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues({
    if (introSeen) IntroSeen.prefsKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = InMemorySecureStorage();
  if (signedIn) {
    await SecureTokenStore(storage).save(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
        verificationRepositoryProvider.overrideWithValue(
          FakeVerificationRepository(),
        ),
        documentPickerProvider.overrideWithValue(FakeDocumentPicker()),
        adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
        notificationsRepositoryProvider.overrideWithValue(
          FakeNotificationsRepository(),
        ),
        deviceTokensRepositoryProvider.overrideWithValue(
          FakeDeviceTokensRepository(),
        ),
        ...overrides,
      ],
      child: const SketchSquareApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Finds [text] inside the current AppBar (tab labels also appear in the nav bar).
/// The Home tab's app bar shows the [Wordmark] instead of a "Home" title.
Finder inAppBar(String text) => find.descendant(
  of: find.byType(AppBar),
  matching: text == 'Home' ? find.byType(Wordmark) : find.text(text),
);
