import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/features/auth/domain/password_strength.dart';
import 'package:sketch_square/features/auth/presentation/widgets/password_strength_meter.dart';

void main() {
  group('PasswordStrength.evaluate', () {
    test('empty and too short', () {
      expect(PasswordStrength.evaluate(''), PasswordStrengthLevel.empty);
      expect(PasswordStrength.evaluate('Ab1!'), PasswordStrengthLevel.weak);
    });

    test('grows with length and variety', () {
      expect(PasswordStrength.evaluate('abcdefgh'), PasswordStrengthLevel.weak);
      expect(PasswordStrength.evaluate('abcdefg1'), PasswordStrengthLevel.fair);
      expect(PasswordStrength.evaluate('Abcdefg1'), PasswordStrengthLevel.good);
      expect(
        PasswordStrength.evaluate('Abcdefghijk1!'),
        PasswordStrengthLevel.strong,
      );
    });
  });

  testWidgets('meter shows the label once something is typed', (tester) async {
    AppTheme.useGoogleFonts = false;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: PasswordStrengthMeter(controller: controller)),
      ),
    );
    expect(find.textContaining('Weak'), findsNothing);

    controller.text = 'abc';
    await tester.pumpAndSettle();
    expect(find.textContaining('Weak'), findsOneWidget);

    controller.text = 'Abcdefghijk1!';
    await tester.pumpAndSettle();
    expect(find.textContaining('Strong'), findsOneWidget);
  });
}
