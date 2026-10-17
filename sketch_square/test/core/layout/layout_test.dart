import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/layout/layout.dart';

void main() {
  test('breakpoints classify widths', () {
    expect(Breakpoints.of(390), ScreenSize.compact);
    expect(Breakpoints.of(599.9), ScreenSize.compact);
    expect(Breakpoints.of(600), ScreenSize.medium);
    expect(Breakpoints.of(1024), ScreenSize.medium);
    expect(Breakpoints.of(1024.1), ScreenSize.expanded);
    expect(Breakpoints.of(1900), ScreenSize.expanded);
  });

  test('adaptive grid goes 2 / 3 / 4 columns by width', () {
    const g = AdaptiveGridDelegate(mainAxisExtent: 300);
    expect(g.columnsFor(350), 2);
    expect(g.columnsFor(700), 2);
    expect(g.columnsFor(850), 3);
    expect(g.columnsFor(1160), 4);
    expect(g.columnsFor(3000), 4);
  });

  testWidgets('ContentFrame caps and centres, full is a no-op', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const key = Key('inner');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ContentFrame(
          width: ContentWidth.form,
          child: SizedBox.expand(key: key),
        ),
      ),
    );
    final box = tester.getRect(find.byKey(key));
    expect(box.width, Breakpoints.formMaxWidth);
    expect(box.center.dx, 800);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ContentFrame(
          width: ContentWidth.full,
          child: SizedBox.expand(key: key),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(key)).width, 1600);
  });
}
