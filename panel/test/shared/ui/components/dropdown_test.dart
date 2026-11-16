import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("arrow activation uses the same input interaction", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    final panel = await tester.showComponent(ChoiceDropdown(controller));
    await panel.tapOn(find.byIcon(Icons.arrow_drop_down));

    expect(panel.shows("Unavailable"), isTrue);
    expect(controller.inputFocusNode.hasPrimaryFocus, isTrue);
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );
    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows("Unavailable"), isFalse);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("keyboard activation opens choices through the input container", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    final panel = await tester.showComponent(ChoiceDropdown(controller));

    await panel.press(LogicalKeyboardKey.tab);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    await panel.press(LogicalKeyboardKey.enter);

    expect(controller.inputFocusNode.hasPrimaryFocus, isTrue);
    expect(panel.shows("Unavailable"), isTrue);
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );
    await panel.press(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await panel.settle();
    expect(panel.shows("Unavailable"), isFalse);
    expect(panel.shows("Beta"), isTrue);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("escape closes choices and returns to field navigation", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    final panel = await tester.showComponent(ChoiceDropdown(controller));
    await panel.tapOn(find.text("Alpha"));
    expect(panel.shows("Unavailable"), isTrue);
    await tester.enterText(find.text("Alpha"), "Be");
    await panel.settle();

    await panel.press(LogicalKeyboardKey.escape);

    expect(panel.shows("Unavailable"), isFalse);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
    expect(panel.shows("Alpha"), isTrue);
    expect(panel.shows("Be"), isFalse);
  });

  testWidgets("leaving the input closes choices without trapping focus", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    final panel = await tester.showComponent(ChoiceDropdown(controller));
    await panel.tapOn(find.text("Alpha"));

    await panel.press(LogicalKeyboardKey.tab);

    expect(panel.shows("Unavailable"), isFalse);
    expect(panel.focused, "Next control");
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets(
    "selection returns focus to the field, ringed once a key is pressed",
    (tester) async {
      final controller = InputFieldController();
      addTearDown(controller.dispose);
      final panel = await tester.showComponent(ChoiceDropdown(controller));
      await panel.tapOn(find.text("Alpha"));

      await panel.tapOn(find.text("Beta").last);

      expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
      expect(
        panel.ring.visible,
        isFalse,
        reason: "pointer focus shows no ring",
      );
      await panel.press(LogicalKeyboardKey.shiftLeft);
      expect(
        panel.ring.rect,
        panel.rectOf(find.byType(InputFieldContainer).first),
      );
      expect(panel.shows("Unavailable"), isFalse);
      expect(panel.shows("Beta"), isTrue);
    },
  );

  testWidgets("typing jumps to a choice", (tester) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    String? chosen;
    final panel = await tester.showComponent(
      SizedBox(
        width: 360,
        child: Dropdown<String>(
          inputFieldController: controller,
          selected: "alpha",
          dropdownMenuEntries: const [
            MenuChoice(value: "alpha", label: "Alpha"),
            MenuChoice(value: "beta", label: "Beta"),
            MenuChoice(value: "gamma", label: "Gamma"),
          ],
          onSelected: (value) => chosen = value,
        ),
      ),
    );
    await panel.tapOn(find.text("Alpha"));
    await tester.enterText(find.text("Alpha"), "g");
    await panel.settle();

    // The one match is the choice Enter takes, marked for assistive
    // technology as well as drawn.
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.spoken == "Gamma" &&
            node.getSemanticsData().flagsCollection.isSelected ==
                Tristate.isTrue,
      ),
      findsOne,
    );
    await panel.press(LogicalKeyboardKey.enter);
    expect(chosen, "gamma");
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });
}
