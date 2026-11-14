import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "an action in the row shows progress until it finishes and runs once",
    (tester) async {
      final finish = Completer<void>();
      var runs = 0;
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          ActionSurface([
            numberedAction(
              0,
              onInvoke: (_) {
                runs++;
                return finish.future;
              },
            ),
          ]),
        ),
      );

      final chip = find.bySemanticsLabel(RegExp("^Action 0"));
      await tester.tap(chip);
      await tester.pump();

      // While it runs the chip is heard as unavailable and its word ripples.
      expect(
        tester.getSemantics(chip).getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(find.text("Action 0"), findsNothing);

      await tester.tap(chip, warnIfMissed: false);
      await tester.pump();
      finish.complete();
      await panel.settle();

      expect(
        tester.getSemantics(chip).getSemanticsData().flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      expect(find.text("Action 0"), findsOneWidget);
      expect(runs, 1);
    },
  );

  testWidgets("an action in the row is heard as a button the user can tap", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ActionSurface([numberedAction(0, onInvoke: (_) {})]),
      ),
    );

    // The chip also reads out its shortcut key after its label.
    final chip = find.semantics
        .byPredicate(
          (node) => node.isButton && node.spoken.startsWith("Action 0"),
        )
        .evaluate()
        .single;

    expect(chip.isTappable, isTrue);
  });

  testWidgets("a hint with several bindings shows each in turn", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ActionSurface([
          ActionShortcut(
            id: "focus",
            label: "Switch Focus",
            description: "Move focus",
            priority: 0,
            activators: const [
              SingleActivator(LogicalKeyboardKey.keyH),
              SingleActivator(LogicalKeyboardKey.keyJ),
            ],
            run: ActionRun.press((_) {}),
          ),
        ]),
      ),
    );

    expect(find.text("H"), findsOneWidget);
    expect(find.text("J"), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await panel.settle();

    expect(find.text("J"), findsOneWidget);
    expect(find.text("H"), findsNothing);
  });
}
