import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("slides forward and backward according to the index", (
    tester,
  ) async {
    var index = 0;
    late StateSetter setState;

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, update) {
          setState = update;
          return DirectionalContentSwitcher(
            index: index,
            child: SizedBox(key: ValueKey(index), width: 200, height: 80),
          );
        },
      ),
    );

    setState(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(_horizontalOffsets(tester).any((offset) => offset > 0), isTrue);
    expect(_horizontalOffsets(tester).any((offset) => offset < 0), isTrue);

    await tester.pumpAndSettle();
    setState(() => index = 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(_horizontalOffsets(tester).any((offset) => offset > 0), isTrue);
    expect(_horizontalOffsets(tester).any((offset) => offset < 0), isTrue);
  });

  testWidgets("animates its height to match the current child", (tester) async {
    var index = 0;
    late StateSetter setState;

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, update) {
          setState = update;
          return DirectionalContentSwitcher(
            index: index,
            child: SizedBox(
              key: ValueKey(index),
              width: 200,
              height: index == 0 ? 40 : 120,
            ),
          );
        },
      ),
    );

    expect(tester.getSize(find.byType(AnimatedSize)).height, 40);

    setState(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final animatedHeight = tester.getSize(find.byType(AnimatedSize)).height;
    expect(animatedHeight, greaterThan(40));
    expect(animatedHeight, lessThan(120));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedSize)).height, 120);
  });

  testWidgets("does not constrain outgoing content to the incoming height", (
    tester,
  ) async {
    var index = 0;
    late StateSetter setState;
    final expanded = ExpansibleController()..expand();
    final collapsed = ExpansibleController();
    addTearDown(expanded.dispose);
    addTearDown(collapsed.dispose);

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, update) {
          setState = update;
          return DirectionalContentSwitcher(
            index: index,
            child: _expansible(
              key: ValueKey(index),
              controller: index == 0 ? expanded : collapsed,
            ),
          );
        },
      ),
    );

    setState(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
  });

  testWidgets("removes motion when animations are disabled", (tester) async {
    await tester.pumpTestApp(
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: DirectionalContentSwitcher(
          index: 0,
          child: SizedBox(key: ValueKey(0), height: 40),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSize>(find.byType(AnimatedSize)).duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}

Widget _expansible({
  required Key key,
  required ExpansibleController controller,
}) => Expansible(
  key: key,
  controller: controller,
  headerBuilder: (context, animation) => const SizedBox(height: 48),
  bodyBuilder: (context, animation) => const SizedBox(height: 86),
  expansibleBuilder: (context, header, body, animation) =>
      Column(mainAxisSize: MainAxisSize.min, children: [header, body]),
);

List<double> _horizontalOffsets(WidgetTester tester) => tester
    .widgetList<SlideTransition>(
      find.descendant(
        of: find.byType(DirectionalContentSwitcher),
        matching: find.byType(SlideTransition),
      ),
    )
    .map((transition) => transition.position.value.dx)
    .toList();
