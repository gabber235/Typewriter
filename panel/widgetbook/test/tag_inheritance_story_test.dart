import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/tag_inheritance_presentation.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a chain shows every ancestor of the Book's tag", (tester) async {
    final panel = await tester.pumpStory(
      tagInheritanceUseCase,
      knobs: {"Topology": "Chain"},
    );

    for (final tag in ["Quest", "Village", "Region"]) {
      expect(panel.shows(tag), isTrue, reason: tag);
    }
  });

  testWidgets("a shared ancestor shows under each tag that inherits it", (
    tester,
  ) async {
    await tester.pumpStory(
      tagInheritanceUseCase,
      knobs: {"Topology": "Shared ancestor"},
    );

    expect(find.text("Quest"), findsOneWidget);
    expect(find.text("Errand"), findsOneWidget);
    expect(find.text("Village"), findsNWidgets(2));
  });

  for (final subject in ["Book", "Tag"]) {
    testWidgets("a ${subject.toLowerCase()} shows branching parents once "
        "expanded", (tester) async {
      final panel = await tester.pumpStory(
        tagInheritanceUseCase,
        knobs: {"Topology": "Branching", "Inspecting": subject},
      );
      expect(panel.shows("Story"), isFalse);

      await panel.tapOn(find.tooltip("Expand").last);

      expect(panel.shows("Story"), isTrue);
      expect(panel.shows("Region"), isTrue);
    });
  }

  testWidgets("the keyboard expands branching parents", (tester) async {
    final panel = await tester.pumpStory(
      tagInheritanceUseCase,
      knobs: {"Topology": "Branching"},
    );

    // The button's own focus, inside its tooltip.
    Focus.of(
      tester.element(
        find.descendant(
          of: find.tooltip("Expand").last,
          matching: find.byIcon(Icons.expand_more),
        ),
      ),
    ).requestFocus();
    await panel.settle();
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.shows("Story"), isTrue);
    expect(panel.shows("Region"), isTrue);
  });
}
