import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/layout/layout.dart';
import 'package:sketch_square/core/widgets/app_card.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(AppCard),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('AppCard lifts on hover and shows a focus ring', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppCard(
              key: const Key('card'),
              onTap: () {},
              child: const SizedBox(width: 120, height: 80),
            ),
          ),
        ),
      ),
    );
    final base = _decoration(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('card'))));
    await tester.pump();
    final hovered = _decoration(tester);
    expect(hovered.boxShadow, isNot(base.boxShadow));
    expect(hovered.border, isNot(base.border));

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(_decoration(tester).boxShadow, base.boxShadow);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = _decoration(tester).border as Border;
    expect(focused.top.width, 2);
  });

  test('AppScrollBehavior allows mouse and trackpad dragging', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
  });
}
