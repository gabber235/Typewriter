import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final activator = SortedLogicalKeyActivator(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.keyK,
  );

  final cases = {
    "both left modifiers": (
      held: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft],
      fires: true,
    ),
    "both right modifiers": (
      held: [LogicalKeyboardKey.controlRight, LogicalKeyboardKey.shiftRight],
      fires: true,
    ),
    "a left and a right modifier": (
      held: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftRight],
      fires: true,
    ),
    "one modifier missing": (
      held: [LogicalKeyboardKey.controlLeft],
      fires: false,
    ),
    "an extra modifier": (
      held: [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.altLeft,
      ],
      fires: false,
    ),
    "no modifier": (held: <LogicalKeyboardKey>[], fires: false),
  };

  for (final MapEntry(key: name, value: (:held, :fires)) in cases.entries) {
    testWidgets("control shift K ${fires ? "fires" : "stays silent"} with "
        "$name held", (tester) async {
      var activations = 0;
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          CallbackShortcuts(
            bindings: {activator: () => activations++},
            child: const Focus(
              autofocus: true,
              child: SizedBox.square(dimension: 40),
            ),
          ),
        ),
      );

      for (final key in held) {
        await tester.sendKeyDownEvent(key);
      }
      await panel.press(LogicalKeyboardKey.keyK);
      for (final key in held.reversed) {
        await tester.sendKeyUpEvent(key);
      }

      expect(activations, fires ? 1 : 0);
    });
  }

  test("keys keep the order they were given in", () {
    expect(activator.orderedKeys, [
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.keyK,
    ]);
    expect(
      activator,
      SortedLogicalKeyActivator(
        LogicalKeyboardKey.keyK,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.control,
      ),
    );
  });
}
