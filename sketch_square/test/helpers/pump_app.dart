import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/app.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/theme/app_theme.dart';

/// Pumps the full app with test-safe overrides (no network font fetches, no
/// native secure storage). Extra [overrides] win over the defaults.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  AppTheme.useGoogleFonts = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
        ...overrides,
      ],
      child: const SketchSquareApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Finds [text] inside the current AppBar (tab labels also appear in the nav bar).
Finder inAppBar(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));
