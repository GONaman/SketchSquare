import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/theme/app_colors.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/core/widgets/blueprint_empty_state.dart';

void main() {
  setUpAll(() => AppTheme.useGoogleFonts = false);

  test('light theme: off-white surface, near-black text, blueprint accent', () {
    final t = AppTheme.light();
    expect(t.brightness, Brightness.light);
    expect(t.colorScheme.primary, AppColors.blueprintBlue);
    expect(t.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(t.colorScheme.onSurface, AppColors.lightText);
    expect(t.useMaterial3, isTrue);
  });

  test('dark theme keeps the accent family with readable contrast', () {
    final t = AppTheme.dark();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(t.colorScheme.primary, AppColors.blueprintBlueLight);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('empty state renders in $brightness theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme:
              brightness == Brightness.light
                  ? AppTheme.light()
                  : AppTheme.dark(),
          home: const Scaffold(
            body: BlueprintEmptyState(
              icon: Icons.home_outlined,
              title: 'Nothing here',
              message: 'Yet',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Nothing here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
