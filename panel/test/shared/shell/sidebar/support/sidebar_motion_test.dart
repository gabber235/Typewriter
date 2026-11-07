import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("shrinking the sidebar never bounces", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(sidebarWithNavigation),
    );
    final initial = panel.boundsOf("Navigation").width;
    await panel.press(LogicalKeyboardKey.comma);
    final shrunk = panel.boundsOf("Navigation").width;
    await panel.press(LogicalKeyboardKey.period);
    expect(panel.boundsOf("Navigation").width, initial);

    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    final widths = <double>[];
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      widths.add(panel.boundsOf("Navigation").width);
    }

    expect(widths.first, greaterThan(shrunk), reason: "it moves");
    expect(widths.every((width) => width >= shrunk - 0.01), isTrue);
    expect(widths.last, closeTo(shrunk, 0.01));
  });
}
