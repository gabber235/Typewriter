import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "with reduced motion, hovering a button tints its fill and it stays in place",
    (tester) async {
      final panel = await tester.showComponent(
        ReducedMotion(child: saveButton()),
      );
      final before = await panel.fillAt(find.text("Save"));
      final at = tester.getRect(find.byType(ButtonContent));

      await panel.hover(find.text("Save"));

      expect(await panel.fillAt(find.text("Save")), isNot(before));
      expect(tester.getRect(find.byType(ButtonContent)), at);
    },
  );

  testWidgets("hovering a button raises it and keeps its fill", (tester) async {
    final panel = await tester.showComponent(saveButton());
    final before = await panel.fillAt(find.text("Save"));
    final top = tester.getRect(find.byType(ButtonContent)).top;

    await panel.hover(find.text("Save"));

    expect(tester.getRect(find.byType(ButtonContent)).top, lessThan(top));
    expect(await panel.fillAt(find.text("Save")), before);
  });

  testWidgets("a pressed button sinks and shrinks, and comes back on release", (
    tester,
  ) async {
    final panel = await tester.showComponent(saveButton());
    final at = tester.getRect(find.byType(ButtonContent));

    final press = await panel.pressDown(find.text("Save"));
    final down = tester.getRect(find.byType(ButtonContent));
    expect(down.center.dy, greaterThan(at.center.dy));
    expect(down.width, lessThan(at.width));

    await press.up();
    await panel.settle();
    expect(tester.getRect(find.byType(ButtonContent)), at);
  });

  for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.enter]) {
    testWidgets(
      "${key.keyLabel} on a focused button presses it in and runs it once",
      (tester) async {
        var runs = 0;
        final panel = await tester.showComponent(
          saveButton(onPressed: () => runs++),
        );
        final at = tester.getRect(find.byType(ButtonContent));
        await panel.focus(find.text("Save"));

        await tester.sendKeyDownEvent(key);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.getRect(find.byType(ButtonContent)).width,
          lessThan(at.width),
        );
        expect(runs, 1);

        await tester.sendKeyUpEvent(key);
        await panel.settle();
        expect(tester.getRect(find.byType(ButtonContent)), at);
        expect(runs, 1);
      },
    );
  }

  testWidgets(
    "a button with no action reads as unavailable and looks pressed in",
    (tester) async {
      final enabled = await tester.showComponent(saveButton());
      final at = tester.getRect(find.byType(ButtonContent));
      await tester.showComponent(
        const Button(face: ButtonFace.filled, label: "Save", onPressed: null),
      );

      expect(
        tester.getRect(find.byType(ButtonContent)).width,
        lessThan(at.width),
      );
      expect(
        tester.getSemantics(find.byType(Button)),
        matchesSemantics(
          label: "Save",
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      await enabled.settle();
    },
  );
}
