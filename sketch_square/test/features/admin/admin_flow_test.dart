import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/admin/presentation/admin_verifications_screen.dart';
import 'package:sketch_square/core/router/app_router.dart';
import 'package:sketch_square/core/router/routes.dart';
import 'package:sketch_square/features/admin/presentation/admin_providers.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';

import '../../helpers/auth_test_utils.dart';
import '../../helpers/fake_admin.dart';
import '../../helpers/pump_app.dart';

final _admin = stubUser.copyWith(role: UserRole.admin);

Future<ProviderContainer> _pumpAdmin(
  WidgetTester tester,
  FakeAdminRepository repo, {
  Future<bool> Function(Uri)? launcher,
}) async {
  useTallScreen(tester);
  final container = await pumpApp(
    tester,
    user: _admin,
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo),
      if (launcher != null)
        documentLauncherProvider.overrideWithValue(launcher),
    ],
  );
  container.read(appRouterProvider).go(AppRoutes.admin);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('admin visibility', () {
    testWidgets('ADMIN sees the Admin entry in Profile and opens the list', (
      tester,
    ) async {
      useTallScreen(tester);
      await pumpApp(
        tester,
        user: _admin,
        overrides: [
          adminRepositoryProvider.overrideWithValue(
            FakeAdminRepository(items: [makeAdminVerification('v1')]),
          ),
        ],
      );
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      expect(inAppBar('Pending verifications'), findsOneWidget);
      expect(find.text('Asha Rao'), findsOneWidget);
    });

    testWidgets('architects have no Admin entry and cannot open /admin', (
      tester,
    ) async {
      useTallScreen(tester);
      final container = await pumpApp(tester);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.admin);
      await tester.pumpAndSettle();
      expect(inAppBar('Pending verifications'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Sign out from Profile returns to sign-in', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(inAppBar('Sign in'), findsOneWidget);
    });
  });

  group('pending list', () {
    testWidgets('shows applicants with COA number and city', (tester) async {
      await _pumpAdmin(
        tester,
        FakeAdminRepository(
          items: [
            makeAdminVerification('v1'),
            makeAdminVerification('v2', name: 'Ravi'),
          ],
        ),
      );
      expect(find.text('Asha Rao'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.textContaining('COA CA/2015/v1'), findsOneWidget);
      expect(find.textContaining('Bengaluru'), findsWidgets);
    });

    testWidgets('empty state', (tester) async {
      await _pumpAdmin(tester, FakeAdminRepository());
      expect(find.text('All caught up'), findsOneWidget);
    });

    testWidgets('loads further pages as the end comes into view', (
      tester,
    ) async {
      final repo = FakeAdminRepository(
        pageSize: 2,
        items: [
          for (var i = 1; i <= 3; i++)
            makeAdminVerification('v$i', name: 'Person $i'),
        ],
      );
      await _pumpAdmin(tester, repo);
      expect(find.text('Person 3'), findsOneWidget);
      expect(repo.cursors, [null, '2']);
    });

    testWidgets('load error shows retry', (tester) async {
      final repo = FakeAdminRepository(items: [makeAdminVerification('v1')])
        ..listError = const ApiException(
          code: ApiErrorCodes.internal,
          message: 'Server down',
        );
      await _pumpAdmin(tester, repo);
      expect(find.text('Server down'), findsOneWidget);

      repo.listError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Asha Rao'), findsOneWidget);
    });
  });

  group('decide', () {
    testWidgets('detail shows applicant, document link opens the URL', (
      tester,
    ) async {
      final opened = <Uri>[];
      await _pumpAdmin(
        tester,
        FakeAdminRepository(
          items: [
            makeAdminVerification(
              'v1',
              documentUrl: 'https://files/doc.pdf?sig=1',
            ),
          ],
        ),
        launcher: (u) async {
          opened.add(u);
          return true;
        },
      );
      await tester.tap(find.text('Asha Rao'));
      await tester.pumpAndSettle();

      expect(inAppBar('Verification request'), findsOneWidget);
      expect(find.text('v1@example.com'), findsOneWidget);
      expect(find.text('CA/2015/v1'), findsOneWidget);

      await tester.tap(find.text('Open document'));
      await tester.pumpAndSettle();
      expect(opened.single.toString(), 'https://files/doc.pdf?sig=1');
    });

    testWidgets(
      'approve asks for confirmation, then removes it from the list',
      (tester) async {
        final repo = FakeAdminRepository(
          items: [
            makeAdminVerification('v1'),
            makeAdminVerification('v2', name: 'Ravi'),
          ],
        );
        await _pumpAdmin(tester, repo);
        await tester.tap(find.text('Asha Rao'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(repo.approved, isEmpty);

        await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(repo.approved, ['v1']);
        expect(inAppBar('Pending verifications'), findsOneWidget);
        expect(find.text('Asha Rao'), findsNothing);
        expect(find.text('Ravi'), findsOneWidget);
        expect(find.text('Asha Rao approved.'), findsOneWidget);
      },
    );

    testWidgets('reject requires a reason and sends it', (tester) async {
      final repo = FakeAdminRepository(items: [makeAdminVerification('v1')]);
      await _pumpAdmin(tester, repo);
      await tester.tap(find.text('Asha Rao'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reject'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Explain why so the architect can fix it'),
        findsOneWidget,
      );
      expect(repo.rejected, isEmpty);

      await tester.enterText(find.byType(TextFormField), '  Blurry scan  ');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reject'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.rejected.single, (id: 'v1', note: 'Blurry scan'));
      expect(inAppBar('Pending verifications'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
    });

    testWidgets('a failed decision stays on the screen with the error', (
      tester,
    ) async {
      final repo = FakeAdminRepository(items: [makeAdminVerification('v1')]);
      await _pumpAdmin(tester, repo);
      await tester.tap(find.text('Asha Rao'));
      await tester.pumpAndSettle();

      repo.error = const ApiException(
        code: ApiErrorCodes.conflict,
        message: 'Already decided',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Approve'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Already decided'), findsOneWidget);
      expect(inAppBar('Verification request'), findsOneWidget);
    });

    testWidgets('decided requests offer no actions', (tester) async {
      final repo = FakeAdminRepository(
        items: [
          makeAdminVerification(
            'v1',
            status: VerificationStatus.rejected,
            reviewNote: 'Blurry',
          ),
        ],
      );
      final container = await _pumpAdmin(tester, repo);
      container.read(appRouterProvider).push(adminVerificationPath('v1'));
      await tester.pumpAndSettle();
      expect(find.text('Blurry'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing);
    });
  });
}
