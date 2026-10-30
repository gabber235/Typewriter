import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/tag_inheritance_presentation.stories.dart";

import "support/stories.dart";

void main() {
  Future<PanelDriver> pump(WidgetTester tester, Map<String, String> knobs) =>
      tester
          .pumpStory(tagInheritanceUseCase, knobs: knobs)
          .then((panel) => panel!);

  /// The disclosure of the last inherited tag, the one inheritance adds.
  Finder lastExpand() => find.tooltip("Expand").last;

  testWidgets("a chain shows every ancestor of the Book's tag", (tester) async {
    final panel = await pump(tester, {"Topology": "Chain"});

    for (final tag in ["Quest", "Village", "Region"]) {
      expect(panel.shows(tag), isTrue, reason: tag);
    }
  });

  testWidgets("a shared ancestor shows under each tag that inherits it", (
    tester,
  ) async {
    await pump(tester, {"Topology": "Shared ancestor"});

    expect(find.text("Quest"), findsOneWidget);
    expect(find.text("Errand"), findsOneWidget);
    expect(find.text("Village"), findsNWidgets(2));
  });

  for (final subject in ["Book", "Tag"]) {
    testWidgets("a ${subject.toLowerCase()} shows branching parents once "
        "expanded", (tester) async {
      final panel = await pump(tester, {
        "Topology": "Branching",
        "Inspecting": subject,
      });
      expect(panel.shows("Story"), isFalse);

      await panel.tapOn(lastExpand());

      expect(panel.shows("Story"), isTrue);
      expect(panel.shows("Region"), isTrue);
    });
  }

  testWidgets("the keyboard expands branching parents", (tester) async {
    final panel = await pump(tester, {"Topology": "Branching"});

    Focus.of(tester.element(lastExpand())).requestFocus();
    await panel.settle();
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.shows("Story"), isTrue);
    expect(panel.shows("Region"), isTrue);
  });
}
