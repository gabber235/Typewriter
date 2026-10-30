import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_presentation_renderer.stories.dart";

import "support/stories.dart";

final _quest = skir.ResourceId(value: "interaction:widgetbook");

void main() {
  Future<PanelDriver> pump(WidgetTester tester, String layout) async {
    return (await tester.pumpStory(
      authoredPresentationInteractionUseCase,
      knobs: {"Layout": layout},
    ))!;
  }

  /// The quest field [name] in the working document.
  skir.DataValue field(PanelDriver panel, String name) =>
      panel.working.resource(_quest)!.authoredField(name)!.authoredPayload;

  List<String> items(PanelDriver panel) => switch (field(panel, "items")) {
    skir.DataValue_listValueWrapper(:final value) => [
      for (final item in value.items)
        switch (item.value) {
          skir.DataValue_stringValueWrapper(:final value) => value,
          final other => "$other",
        },
    ],
    final other => throw StateError("Items are no list: $other"),
  };

  Map<String, String> metadata(PanelDriver panel) =>
      switch (field(panel, "metadata")) {
        skir.DataValue_mapValueWrapper(:final value) => {
          for (final row in value.rows) "${row.key}": "${row.value}",
        },
        final other => throw StateError("Metadata is no map: $other"),
      };

  testWidgets("the details switch shows and hides the details", (tester) async {
    final panel = await pump(tester, "Toggle");
    expect(panel.shows("Details are visible"), isTrue);

    await panel.tapOn(find.bySemanticsLabel("On"));

    expect(panel.shows("Details are hidden"), isTrue);
  });

  testWidgets("tabs show the content of the chosen tab", (tester) async {
    final panel = await pump(tester, "Tabs");
    expect(panel.shows("General settings"), isTrue);

    await panel.tapOn(find.text("Advanced"));
    expect(panel.shows("Advanced settings"), isTrue);
    await panel.tapOn(find.text("History").last);
    expect(panel.shows("Change history"), isTrue);
  });

  testWidgets("Add item appends an item the quest stores", (tester) async {
    final panel = await pump(tester, "List");

    await panel.tapOn(find.text("Add item"));

    expect(panel.shows("Item 4"), isTrue);
    expect(items(panel).last, "Item 4");
  });

  testWidgets("moving the first item down by keyboard reorders the list", (
    tester,
  ) async {
    final panel = await pump(tester, "List");
    final before = items(panel);

    await panel.tapOn(find.tooltip("Reorder item").first);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await panel.settle();

    expect(items(panel), [before[1], before[0], ...before.skip(2)]);
  });

  testWidgets("an added map entry edits its key and value in place", (
    tester,
  ) async {
    final panel = await pump(tester, "Map");
    final before = metadata(panel);

    await panel.tapOn(find.text("Add entry"));
    await tester.enterText(find.text("chapter"), "chapter_two");
    await panel.settle();
    await tester.enterText(find.text("Arrival"), "Departure");
    await panel.settle();

    expect(metadata(panel), {
      ...before,
      "${skir.DataValue.wrapStringValue("chapter_two")}":
          "${skir.DataValue.wrapStringValue("Departure")}",
    });
  });

  testWidgets("Archive asks for confirmation before it archives", (
    tester,
  ) async {
    final panel = await pump(tester, "Toggle");

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
    final panel = await pump(tester, "Realm action");

    await panel.tapOn(find.text("Reload from Realm"));

    expect(
      panel.shows(
        "The editor action did not complete: Bad state: Reload is unavailable",
      ),
      isTrue,
    );
  });

  const identifier = "book:019d1c2a8f7b7cc18c2a4a7b2fd1e281";

  Future<PanelDriver> heading(WidgetTester tester, String multiple) async =>
      (await tester.pumpStory(
        resourceHeadingUseCase,
        knobs: {"Title": "Lost Village", "Multiple selection": multiple},
      ))!;

  testWidgets("a heading names one selected resource and its identifier", (
    tester,
  ) async {
    final panel = await heading(tester, "false");

    expect(panel.shows("Lost Village"), isTrue);
    expect(panel.shows(identifier), isTrue);
  });

  testWidgets("a heading steps aside when several resources are selected", (
    tester,
  ) async {
    final panel = await heading(tester, "true");

    expect(panel.shows("Lost Village"), isFalse);
    expect(panel.shows(identifier), isFalse);
  });
}
