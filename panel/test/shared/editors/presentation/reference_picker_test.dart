import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const welcome = ReferencePickerCandidate(
    id: "welcome",
    value: "selected",
    label: "Welcome",
  );
  const locked = ReferencePickerCandidate(
    id: "locked",
    value: "locked",
    label: "Locked",
    disabledReason: "The opposite endpoint rejects this type",
  );

  testWidgets("Enter picks the focused candidate", (tester) async {
    final (panel, outcome) = await tester.openFromButton<String>(
      (context) =>
          showReferencePicker<String>(context, candidates: const [welcome]),
    );

    await panel.press(LogicalKeyboardKey.enter);

    expect(outcome.completed, isTrue);
    expect(outcome.result, "selected");
  });

  testWidgets("Escape cancels the picker without a result", (tester) async {
    final (panel, outcome) = await tester.openFromButton<String>(
      (context) =>
          showReferencePicker<String>(context, candidates: const [welcome]),
    );

    // The first Escape dismisses the query suggestions the focused field
    // shows; the second closes the picker.
    await panel.press(LogicalKeyboardKey.escape);
    await panel.press(LogicalKeyboardKey.escape);

    expect(outcome.completed, isTrue);
    expect(outcome.result, isNull);
  });

  testWidgets("an unavailable reference stays explained and cannot be picked", (
    tester,
  ) async {
    final (panel, outcome) = await tester.openFromButton<String>(
      (context) =>
          showReferencePicker<String>(context, candidates: const [locked]),
    );

    await panel.press(LogicalKeyboardKey.enter);

    expect(outcome.completed, isFalse);
    expect(panel.shows("The opposite endpoint rejects this type"), isTrue);
    // The first Escape dismisses the query suggestions the focused field
    // shows; the second closes the picker.
    await panel.press(LogicalKeyboardKey.escape);
    await panel.press(LogicalKeyboardKey.escape);
    expect(outcome.completed, isTrue);
    expect(outcome.result, isNull);
  });
}
