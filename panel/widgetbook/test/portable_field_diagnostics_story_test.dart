import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

import "support/stories.dart";

const _shortTitle = "Use at least three characters";

void main() {
  testWidgets("a too short title says why and clears once corrected, keeping "
      "the field focused", (tester) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    expect(panel.shows(_shortTitle), isTrue);

    await panel.field("Title").type("Find the lantern");
    await tester.runStory();

    expect(panel.shows(_shortTitle), isFalse);
    expect(panel.field("Title").value, "Find the lantern");
    expect(panel.field("Title").isFocused, isTrue);
  });

  testWidgets("a title made too short says why only once typing pauses", (
    tester,
  ) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    await panel.field("Title").type("Find the lantern");
    await tester.runStory();

    // One keystroke, then a pause shorter than the wait before its problem
    // shows.
    panel.field("Title").keystroke("Fi");
    await tester.runStory(duration: const Duration(milliseconds: 300));
    expect(panel.shows(_shortTitle), isFalse);

    await tester.runStory();
    expect(panel.shows(_shortTitle), isTrue);
  });

  testWidgets("the quest stays clear while a new title problem waits, then "
      "tints with it", (tester) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    await panel.field("Title").type("Find the lantern");
    await tester.runStory();
    expect(panel.header("Quest").tinted, isFalse);

    panel.field("Title").keystroke("Fi");
    await tester.runStory(duration: const Duration(milliseconds: 300));
    expect(panel.shows(_shortTitle), isFalse);
    expect(panel.header("Quest").tinted, isFalse);

    await tester.runStory();
    expect(panel.shows(_shortTitle), isTrue);
    expect(panel.header("Quest").tinted, isTrue);
  });

  testWidgets("the quest marks a new title problem together with its "
      "message", (tester) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    await panel.field("Title").type("Find the lantern");
    await tester.runStory();
    expect(panel.header("Quest").marked, isFalse);

    panel.field("Title").keystroke("Fi");
    await tester.runStory(duration: const Duration(milliseconds: 300));
    expect(panel.header("Quest").marked, isFalse);

    await tester.runStory();
    expect(panel.shows(_shortTitle), isTrue);
    expect(panel.header("Quest").marked, isTrue);
  });

  testWidgets("a corrected title says Fixed, then its message closes", (
    tester,
  ) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);

    await panel.field("Title").focus();
    panel.field("Title").keystroke("Find the lantern");
    await tester.runStory(duration: const Duration(milliseconds: 400));
    expect(panel.shows("Fixed"), isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.runStory(duration: const Duration(seconds: 2));
    expect(panel.shows("Fixed"), isFalse);
    expect(panel.shows(_shortTitle), isFalse);
  });

  testWidgets("a collapsed quest still reports its field diagnostic and "
      "expands to the same draft", (tester) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    await panel.field("Title").type("Fi");
    await tester.runStory();

    await panel.tapOn(find.tooltip("Collapse"));
    expect(panel.field("Title").exists, isFalse);
    expect(find.tooltip("1 field diagnostic"), findsOneWidget);

    await panel.tapOn(find.tooltip("Expand"));
    expect(panel.field("Title").value, "Fi");
    expect(panel.shows(_shortTitle), isTrue);
  });

  testWidgets("a quest that starts collapsed shows the marker", (tester) async {
    final panel = await tester.pumpStory(
      portableFieldValidationUseCase,
      knobs: {"Collapsed header": "true", "Diagnostic severity": "Warning"},
    );

    expect(panel.field("Title").exists, isFalse);
    expect(find.tooltip("1 field diagnostic"), findsOneWidget);
  });

  testWidgets("an objective count that is not a number keeps the draft and "
      "clears on correction", (tester) async {
    final panel = await tester.pumpStory(portableFieldValidationUseCase);
    final objectives = panel.field("Objectives");

    await objectives.type("-");
    await tester.runStory();
    expect(panel.shows("Enter a valid number"), isTrue);
    expect(objectives.value, "-");
    expect(objectives.isFocused, isTrue);

    await objectives.type("7");
    await tester.runStory();
    expect(panel.shows("Enter a valid number"), isFalse);
    expect(objectives.value, "7");
  });

  testWidgets("general feedback on a read only search result shows its message "
      "once focused from the keyboard", (tester) async {
    final panel = await tester.pumpStory(
      portableFieldValidationUseCase,
      knobs: {
        "General message": "true",
        "Presentation role": "Search result",
        "Read only": "true",
      },
    );
    expect(find.text(_shortTitle), findsNothing);

    for (var tab = 0; tab < 20 && !panel.shows(_shortTitle); tab++) {
      await panel.press(LogicalKeyboardKey.tab);
    }

    expect(find.text(_shortTitle), findsOneWidget);
  });
}
