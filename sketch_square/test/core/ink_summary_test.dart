import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/core/widgets/widgets.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('InkHeroCard and SummaryRow render in $brightness at 1.3x', (
      tester,
    ) async {
      AppTheme.useGoogleFonts = false;
      await tester.pumpWidget(
        MaterialApp(
          theme:
              brightness == Brightness.light
                  ? AppTheme.light()
                  : AppTheme.dark(),
          builder:
              (context, c) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: c!,
              ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  InkHeroCard(child: Text('Balance')),
                  SummaryRow(label: 'Subtotal (3 drawings)', value: '₹64,997'),
                  SummaryRow(label: 'Total', value: '₹64,997', emphasis: true),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('₹64,997'), findsNWidgets(2));
    });
  }
}
