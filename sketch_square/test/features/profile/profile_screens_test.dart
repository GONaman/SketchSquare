import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/core/theme/theme_mode_provider.dart';
import 'package:sketch_square/features/architects/data/architects_providers.dart';
import 'package:sketch_square/features/architects/domain/architect_profile.dart';
import 'package:sketch_square/features/architects/domain/architect_summary.dart';
import 'package:sketch_square/features/auth/domain/auth_state.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/auth/presentation/auth_repository_provider.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/profile/data/profile_providers.dart';
import 'package:sketch_square/features/purchases/data/purchases_providers.dart';

import '../../helpers/commerce_fixtures.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';
import '../drawings/fixtures.dart';
import '../purchases/fakes.dart';
import 'fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profile;
  late FakeAvatarPicker picker;

  setUp(() {
    auth = FakeAuthRepository(
      user: stubUser.copyWith(
        fullName: 'Asha Rao',
        city: 'Pune',
        phone: '+919999999999',
      ),
    );
    profile = FakeProfileRepository(auth);
    picker = FakeAvatarPicker(image: fakeAvatar());
  });

  Future<ProviderContainer> open(
    WidgetTester tester, {
    String path = AppRoutes.profile,
    User? user,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (user != null) auth.user = user;
    final container = await pumpApp(
      tester,
      overrides: [
        ...discoveryFakes(),
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profile),
        avatarPickerProvider.overrideWithValue(picker),
        purchasesRepositoryProvider.overrideWithValue(
          FakePurchasesRepository(items: [fakePurchase()]),
        ),
        architectsRepositoryProvider.overrideWithValue(
          FakeArchitectsRepository(
            profile: ArchitectProfile(
              architect: const ArchitectSummary(
                id: 'u',
                fullName: 'Asha Rao',
                city: 'Pune',
                architectRating: 4.5,
                ratingCount: 12,
              ),
              drawings: CursorPage(
                items: [fakeDrawing(id: 'd1'), fakeDrawing(id: 'd2')],
              ),
            ),
          ),
        ),
      ],
    );
    if (path != AppRoutes.profile) {
      // Open via the Profile tab so the back stack is realistic.
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      container.read(appRouterProvider).push(path);
      await tester.pumpAndSettle();
    } else {
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
    }
    return container;
  }

  testWidgets('profile shows identity, verified badge, public stats', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Pune'), findsOneWidget);
    expect(find.text('Verified architect'), findsOneWidget);
    expect(find.text('4.5 ★'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Free downloads: 0 of 20 used'), findsOneWidget);
    expect(find.byKey(const Key('tile-admin')), findsNothing);
  });

  testWidgets('admin tile only for ADMIN', (tester) async {
    await open(tester, user: stubUser.copyWith(role: UserRole.admin));
    expect(find.byKey(const Key('tile-admin')), findsOneWidget);
  });

  testWidgets('unregistered routes degrade to "Coming soon"', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('tile-my-drawings')));
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('My purchases tile opens the library', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('tile-purchases')));
    await tester.pumpAndSettle();

    expect(find.text('My purchases'), findsOneWidget);
    expect(find.text('Modern Villa'), findsOneWidget);
  });

  testWidgets('changing the avatar uploads and refreshes the header', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('change-avatar')));
    await tester.pumpAndSettle();

    expect(profile.avatars.single.contentType, 'image/png');
    expect(find.text('Photo updated'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('profile-avatar')),
    );
    expect(avatar.backgroundImage, isNotNull);
  });

  testWidgets('avatar picker errors are shown and nothing is uploaded', (
    tester,
  ) async {
    picker.error = const ApiException(
      code: ApiErrorCodes.validation,
      message: 'Choose a JPG, PNG or WebP image.',
    );
    await open(tester);

    await tester.tap(find.byKey(const Key('change-avatar')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a JPG, PNG or WebP image.'), findsOneWidget);
    expect(profile.avatars, isEmpty);
  });

  testWidgets('cancelled picker does nothing', (tester) async {
    picker.image = null;
    await open(tester);

    await tester.tap(find.byKey(const Key('change-avatar')));
    await tester.pumpAndSettle();

    expect(profile.avatars, isEmpty);
    expect(find.text('Photo updated'), findsNothing);
  });

  group('edit contact', () {
    testWidgets('name and address are read-only', (tester) async {
      await open(tester, path: AppRoutes.profileEdit);

      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('field-name')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('field-address')))
            .enabled,
        isFalse,
      );
      expect(find.textContaining('contacting support'), findsOneWidget);
    });

    testWidgets('validates phone and city before calling the API', (
      tester,
    ) async {
      await open(tester, path: AppRoutes.profileEdit);

      await tester.enterText(find.byKey(const Key('field-phone')), '123');
      await tester.enterText(find.byKey(const Key('field-city')), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter your city'), findsOneWidget);
      expect(profile.contactCalls, isEmpty);
    });

    testWidgets('saves only changed fields and refreshes the user', (
      tester,
    ) async {
      await open(tester, path: AppRoutes.profileEdit);

      await tester.enterText(find.byKey(const Key('field-city')), 'Goa');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(profile.contactCalls.single, (phone: null, city: 'Goa'));
      expect(find.text('Details saved'), findsOneWidget);
      expect(find.text('Goa'), findsOneWidget); // back on the profile header
    });

    testWidgets('phone is normalised before sending', (tester) async {
      await open(tester, path: AppRoutes.profileEdit);

      await tester.enterText(
        find.byKey(const Key('field-phone')),
        '+91 98765-43210',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(profile.contactCalls.single.phone, '+919876543210');
    });

    testWidgets('server error is shown and the form stays', (tester) async {
      profile.error = const ApiException(
        code: ApiErrorCodes.internal,
        message: 'Something went wrong',
      );
      await open(tester, path: AppRoutes.profileEdit);

      await tester.enterText(find.byKey(const Key('field-city')), 'Goa');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Edit contact details'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('theme toggle drives appThemeModeProvider', (tester) async {
      final container = await open(tester, path: AppRoutes.settings);
      expect(container.read(appThemeModeProvider), ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(container.read(appThemeModeProvider), ThemeMode.dark);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(container.read(appThemeModeProvider), ThemeMode.light);
    });

    testWidgets('sign out asks for confirmation then returns to sign-in', (
      tester,
    ) async {
      final container = await open(tester, path: AppRoutes.settings);

      await tester.tap(find.byKey(const Key('sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(container.read(authControllerProvider), isA<Authenticated>());

      await tester.tap(find.byKey(const Key('sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-sign-out')));
      await tester.pumpAndSettle();

      expect(container.read(authControllerProvider), isA<Unauthenticated>());
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}
