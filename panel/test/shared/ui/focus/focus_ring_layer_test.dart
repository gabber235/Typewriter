import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      "a focused button shows the blue ring and no fill at 400 px (${brightness.name})",
      (tester) async {
        final panel = await tester.pumpPanel(
          [
            window(const Size(400, 800)),
            if (brightness == Brightness.dark) dark,
          ],
          at: PanelLocation.component(
            TextButton(onPressed: () {}, child: const Text("Invite")),
          ),
        );
        await panel.press(LogicalKeyboardKey.tab);
        final colors = panel.theme.colors;
        expect(panel.ring.rect, panel.rectOf(find.byType(InkWell)));
        expect(panel.ring.color, colors.focusRing);
        expect(
          find.byType(TextButton),
          isNot(
            paints..rrect(
              style: PaintingStyle.fill,
              color: colors.focusRing.withValues(alpha: 0.12),
            ),
          ),
        );
      },
    );
  }

  testWidgets("a pointer press hides the ring and a key brings it back", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        TextButton(onPressed: () {}, child: const Text("Invite")),
      ),
    );
    await panel.press(LogicalKeyboardKey.tab);
    await panel.tapOn(find.text("Invite"));
    expect(panel.ring.visible, isFalse);
    await panel.press(LogicalKeyboardKey.tab);
    expect(panel.ring.visible, isTrue);
  });

  testWidgets("a list cursor carries the ring while the field keeps focus", (
    tester,
  ) async {
    final active = ValueNotifier(0);
    addTearDown(active.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 200, child: TextField(autofocus: true)),
            ValueListenableBuilder(
              valueListenable: active,
              builder: (context, index, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in [0, 1])
                    RingCursor(
                      active: row == index,
                      child: Text("Result $row"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // Any key puts the panel in keyboard highlight mode.
    await panel.press(LogicalKeyboardKey.arrowDown);
    expect(panel.ring.rect, panel.rectOf(find.text("Result 0")));
    active.value = 1;
    await panel.settle();
    expect(panel.ring.rect, panel.rectOf(find.text("Result 1")));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
      reason: "the field keeps focus",
    );
    active.value = -1;
    await panel.settle();
    expect(
      panel.ring.visible,
      isFalse,
      reason: "a typed field shows its own border, not the ring",
    );
  });

  testWidgets(
    "after the layer unmounts, a highlight mode change does not throw",
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: buildTheme(Brightness.light),
            child: const FocusRingLayer(child: SizedBox()),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      // Pointer then key input switches FocusManager.highlightMode both ways.
      await tester.tapAt(Offset.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.takeException(), isNull);
    },
  );
}
