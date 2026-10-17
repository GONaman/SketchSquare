import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/theme/app_theme.dart';
import 'package:sketch_square/core/widgets/widgets.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  AppTheme.useGoogleFonts = false;
  await tester.pumpWidget(
    MaterialApp(
      theme:
          brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      builder:
          (context, c) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: c!,
          ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('price formatting', () {
    test('formatPaise uses Indian grouping', () {
      expect(formatPaise(149900), '₹1,499');
      expect(formatPaise(12499900), '₹1,24,999');
      expect(formatPaise(150), '₹1.50');
    });

    test('formatPaiseCompact abbreviates', () {
      expect(formatPaiseCompact(99900), '₹999');
      expect(formatPaiseCompact(1250000), '₹12.5K');
      expect(formatPaiseCompact(12000000), '₹1.2L');
      expect(formatPaiseCompact(2400000000), '₹2.4Cr');
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('kit renders in $brightness at 1.3x text', (tester) async {
      await _pump(
        tester,
        brightness: brightness,
        textScale: 1.3,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Latest', subtitle: 'Fresh'),
            const PlotSizeBadge(lengthFt: 30, breadthFt: 40),
            const PriceText(paise: 149900),
            const StatusPill(label: 'Published', tone: StatusTone.success),
            const StatTile(value: '12', label: 'Sales'),
            const AppAvatar(name: 'Anita Rao'),
            PrimaryButton(label: 'Save', onPressed: () {}),
            SecondaryButton(label: 'Cancel', onPressed: () {}),
            const AppTextField(label: 'Title'),
            const AppCard(child: Text('Card')),
            const SizedBox(
              width: 180,
              height: 280,
              child: DrawingCardSkeleton(),
            ),
            const ListRowSkeleton(),
            const ErrorState(message: 'Nope', onRetry: _noop),
          ],
        ),
      );
      expect(find.text('Latest'), findsOneWidget);
      expect(find.text('30×40 ft'), findsOneWidget);
      expect(find.text('₹1,499'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PrimaryButton shows a spinner and ignores taps when loading', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      PrimaryButton(label: 'Pay', loading: true, onPressed: () => taps++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 0);
  });

  testWidgets('PrimaryButton fires onPressed', (tester) async {
    var taps = 0;
    await _pump(tester, PrimaryButton(label: 'Pay', onPressed: () => taps++));
    await tester.tap(find.text('Pay'));
    expect(taps, 1);
  });

  testWidgets('EmptyState shows its action', (tester) async {
    await _pump(
      tester,
      EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message: 'Try again',
        action: SecondaryButton(label: 'Clear', onPressed: () {}),
      ),
    );
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });
}

void _noop() {}
