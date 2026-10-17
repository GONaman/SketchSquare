import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/auth/presentation/intro_video.dart';

void main() {
  testWidgets('shows the static backdrop when the video cannot play', (
    tester,
  ) async {
    // `flutter test` has no video plugin, so initialising the controller
    // fails exactly like an undecodable placeholder asset would.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: IntroVideo(muted: true))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('intro-fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
