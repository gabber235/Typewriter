import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_presentation_renderer.stories.dart";

import "support/authored_values.dart";
import "support/stories.dart";

final _quest = skir.ResourceId(value: "interaction:widgetbook");

void main() {
  testWidgets("the details switch shows and hides the details", (tester) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "Toggle"},
    );
    expect(panel.shows("Details are visible"), isTrue);

    await panel.tapOn(find.bySemanticsLabel("On"));

    expect(panel.shows("Details are hidden"), isTrue);
  });

  testWidgets("tabs show the content of the chosen tab", (tester) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "Tabs"},
    );
    expect(panel.shows("General settings"), isTrue);

    await panel.tapOn(find.text("Advanced"));
    expect(panel.shows("Advanced settings"), isTrue);
    await panel.tapOn(find.text("History").last);
    expect(panel.shows("Change history"), isTrue);
  });

  testWidgets("Add item appends an item the quest stores", (tester) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "List"},
    );

    await panel.tapOn(find.text("Add item"));

    expect(panel.shows("Item 4"), isTrue);
    expect(
      panel.working.resource(_quest)!.authoredField("items")!.itemTexts.last,
      "Item 4",
    );
  });

  testWidgets("moving the first item down by keyboard reorders the list", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "List"},
    );
    final before = panel.working
        .resource(_quest)!
        .authoredField("items")!
        .itemTexts;

    await panel.tapOn(find.tooltip("Reorder item").first);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await panel.settle();

    expect(panel.working.resource(_quest)!.authoredField("items")!.itemTexts, [
      before[1],
      before[0],
      ...before.skip(2),
    ]);
  });

  testWidgets("an added map entry edits its key and value in place", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "Map"},
    );
    final before = panel.working
        .resource(_quest)!
        .authoredField("metadata")!
        .entryTexts;

    await panel.tapOn(find.text("Add entry"));
    await tester.enterText(find.text("chapter"), "chapter_two");
    await panel.settle();
    await tester.enterText(find.text("Arrival"), "Departure");
    await panel.settle();

    expect(
      panel.working.resource(_quest)!.authoredField("metadata")!.entryTexts,
      {
        ...before,
        "${skir.DataValue.wrapStringValue("chapter_two")}":
            "${skir.DataValue.wrapStringValue("Departure")}",
      },
    );
  });

  testWidgets("Archive asks for confirmation before it archives", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "Toggle"},
    );

    await panel.tapOn(find.byTooltip("More actions"));
    await panel.tapOn(find.bySemanticsLabel("Archive"));
    expect(panel.shows("Archive quest?"), isTrue);
    expect(
      panel.shows("The quest will no longer be available to players."),
      isTrue,
    );
    await panel.tapOn(find.bySemanticsLabel("Archive"));

    expect(panel.shows("Archived quest"), isTrue);
  });

  testWidgets("a Realm action the panel cannot run reports why", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": "Realm action"},
    );

    await panel.tapOn(find.text("Reload from Realm"));

    expect(
      panel.shows(
        "The editor action did not complete: Bad state: Reload is unavailable",
      ),
      isTrue,
    );
  });

  const identifier = "book:019d1c2a8f7b7cc18c2a4a7b2fd1e281";

  testWidgets("a heading names one selected resource and its identifier", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourceHeadingUseCase,
      knobs: {"Title": "Lost Village", "Multiple selection": "false"},
    );

    expect(panel.shows("Lost Village"), isTrue);
    expect(panel.shows(identifier), isTrue);
  });

  testWidgets("a heading steps aside when several resources are selected", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourceHeadingUseCase,
      knobs: {"Title": "Lost Village", "Multiple selection": "true"},
    );

    expect(panel.shows("Lost Village"), isFalse);
    expect(panel.shows(identifier), isFalse);
  });
}
