import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final target = TestSelectableIdentifier(id: "target");

  for (final (key, name) in [
    (LogicalKeyboardKey.space, "Space"),
    (LogicalKeyboardKey.enter, "Enter"),
  ]) {
    testWidgets("$name on a focused row selects it when let go", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(SelectionCard(target)),
      );
      await panel.tabTo("Target");

      await panel.keyDown(key);
      expect(
        panel.container.read(selectionProvider),
        isEmpty,
        reason: "key down only presses",
      );
      await panel.keyUp(key);

      expect(panel.container.read(selectionProvider), [target]);
    });

    testWidgets("Escape while $name is down on a row selects nothing", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(SelectionCard(target)),
      );
      await panel.tabTo("Target");

      await panel.keyDown(key);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await panel.keyUp(key);

      expect(panel.container.read(selectionProvider), isEmpty);
    });
  }
}
