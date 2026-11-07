import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a right click opens the menu at the pointer", (tester) async {
    final panel = await tester.showComponent(const ContextMenuTarget([]));
    final target = tester.getRect(find.byType(ContextMenuRegion));
    final pointer = target.topLeft + const Offset(40, 30);

    await tester.tapAt(pointer, buttons: kSecondaryButton);
    await panel.settle();

    expect(panel.menu.entries, ["Rename", "Delete"]);
    final first = panel.menu.rectOf("Rename");
    expect((first.top - pointer.dy).abs(), lessThan(16));
    expect((first.left - pointer.dx).abs(), lessThan(16));
  });

  testWidgets(
    "arrow keys move, Enter chooses, Esc leaves and focus is back on the opener",
    (tester) async {
      final chosen = <String>[];
      final panel = await tester.showComponent(ContextMenuTarget(chosen));
      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "Target");

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await panel.settle();
      expect(panel.focused, "Rename");
      await panel.press(LogicalKeyboardKey.arrowDown);
      expect(panel.focused, "Delete");
      await panel.press(LogicalKeyboardKey.enter);
      expect(chosen, ["Delete"]);
      expect(panel.menu.isOpen, isFalse);
      expect(panel.focused, "Target");

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await panel.settle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      // The menu goes back into its control; it does not vanish.
      expect(find.text("Rename"), findsOneWidget);
      await panel.settle();
      expect(find.text("Rename"), findsNothing);
      expect(panel.focused, "Target");
    },
  );
}
