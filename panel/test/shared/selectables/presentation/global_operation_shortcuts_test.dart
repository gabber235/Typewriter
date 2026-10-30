import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final target = TestSelectableIdentifier(id: "target");

  testWidgets("in normal mode a selection shortcut runs its operation", (
    tester,
  ) async {
    final (:panel, :operation) = await tester.pumpGatedShortcuts(target);
    await panel.item("Target").select();
    expect(panel.container.read(selectionProvider), [target]);

    await panel.press(LogicalKeyboardKey.keyR);

    expect(operation.executions, 1);
  });

  testWidgets("in normal mode escape clears the selection", (tester) async {
    final (:panel, operation: _) = await tester.pumpGatedShortcuts(target);
    await panel.item("Target").select();
    expect(panel.container.read(selectionProvider), [target]);

    await panel.press(LogicalKeyboardKey.escape);

    expect(panel.container.read(selectionProvider), isEmpty);
  });

  testWidgets("while typing selection shortcuts stay off", (tester) async {
    final (:panel, :operation) = await tester.pumpGatedShortcuts(target);
    await panel.item("Target").select();
    expect(panel.container.read(selectionProvider), [target]);

    await panel.tapOn(panel.labeled("Name"));
    expect(panel.focused, "Name");
    await panel.press(LogicalKeyboardKey.keyR);

    expect(operation.executions, 0);
    expect(panel.container.read(selectionProvider), [target]);
  });

  testWidgets("outside normal mode selection shortcuts and clearing stay off", (
    tester,
  ) async {
    final (:panel, :operation) = await tester.pumpGatedShortcuts(target);
    await panel.item("Target").select();
    expect(panel.container.read(selectionProvider), [target]);

    panel.container
        .read(currentInteractionModeProvider.notifier)
        .setMode(InsertMode("elsewhere"));
    await panel.settle();
    await panel.press(LogicalKeyboardKey.keyR);
    await panel.press(LogicalKeyboardKey.escape);

    expect(operation.executions, 0);
    expect(panel.container.read(selectionProvider), [target]);
  });
}
