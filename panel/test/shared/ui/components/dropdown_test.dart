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

  testWidgets("selection restores a visible field focus highlight", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    final panel = await tester.showComponent(ChoiceDropdown(controller));
    await panel.tapOn(find.text("Alpha"));

    await panel.tapOn(find.text("Beta").last);

    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    final highlight = tester.widget<FocusHighlight>(
      find
          .descendant(
            of: find.byType(InputFieldContainer),
            matching: find.byType(FocusHighlight),
          )
          .first,
    );
    expect(highlight.type, FocusType.focus);
    expect(panel.shows("Unavailable"), isFalse);
    expect(panel.shows("Beta"), isTrue);
  });
}
