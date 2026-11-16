import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("comma shrinks the sidebar and period restores it", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(sidebarWithNavigation),
    );
    final initial = panel.boundsOf("Navigation").width;

    await panel.press(LogicalKeyboardKey.comma);
    expect(panel.boundsOf("Navigation").width, lessThan(initial));

    await panel.press(LogicalKeyboardKey.period);
    expect(panel.boundsOf("Navigation").width, initial);
  });

  testWidgets("shift resizes the sidebar in larger steps", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(sidebarWithNavigation),
    );
    final initial = panel.boundsOf("Navigation").width;
    await panel.press(LogicalKeyboardKey.comma);
    final smallStep = initial - panel.boundsOf("Navigation").width;
    await panel.press(LogicalKeyboardKey.period);

    await panel.pressShifted(LogicalKeyboardKey.comma);
    final largeStep = initial - panel.boundsOf("Navigation").width;
    expect(largeStep, greaterThan(smallStep));

    await panel.pressShifted(LogicalKeyboardKey.period);
    expect(panel.boundsOf("Navigation").width, initial);
  });
}
