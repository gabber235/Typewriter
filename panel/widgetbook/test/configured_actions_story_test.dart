import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/configured_actions.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("Enter on a focused action runs it", (tester) async {
    final panel = (await tester.pumpStory(configuredActionsUseCase))!;
    expect(panel.shows("Draft"), isTrue);

    await _focus(panel, "Save quest");
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.shows("Saved"), isTrue);
  });

  testWidgets("the menu explains why Delete is unavailable and runs Mark "
      "ready", (tester) async {
    final panel = (await tester.pumpStory(configuredActionsUseCase))!;

    await panel.tapOn(find.text("More"));
    expect(panel.shows("Players can start it"), isTrue);
    expect(panel.shows("Remove its objectives first"), isTrue);

    await panel.tapOn(find.text("Delete quest"));
    expect(panel.shows("Deleted"), isFalse);

    await panel.tapOn(find.text("Mark ready"));
    expect(panel.shows("Ready"), isTrue);
    expect(panel.shows("Players can start it"), isFalse);
  });

  testWidgets("the menu opens and runs Mark ready from the keyboard, "
      "skipping the unavailable Delete", (tester) async {
    final panel = (await tester.pumpStory(configuredActionsUseCase))!;

    await _focus(panel, "More");
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.shows("Players can start it"), isTrue);
    expect(panel.shows("Remove its objectives first"), isTrue);
    // Arrow down moves into the menu, onto its first available action.
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.shows("Ready"), isTrue);
    expect(panel.shows("Deleted"), isFalse);
    expect(panel.shows("Players can start it"), isFalse);
  });

  testWidgets("a read only quest keeps its actions visible but runs none", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      configuredActionsUseCase,
      knobs: {"Read only": "true"},
    ))!;

    await panel.tapOn(find.text("Save quest"));
    await panel.tapOn(find.text("Publish"));

    expect(panel.shows("Save quest"), isTrue);
    expect(panel.shows("Draft"), isTrue);
  });

  testWidgets("the quest summary switches tabs from the keyboard and shows "
      "its rewards on focus", (tester) async {
    final panel = (await tester.pumpStory(configuredDisplaysUseCase))!;
    expect(panel.shows("3 of 10 objectives"), isTrue);
    expect(panel.shows("Find the lost lantern before nightfall"), isTrue);

    await _focus(panel, "Details");
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.shows("Starts at the village gate"), isTrue);
    expect(panel.shows("Find the lost lantern before nightfall"), isFalse);

    await _focus(panel, "Rewards");
    expect(find.text("50 coins and the Lantern"), findsOneWidget);
  });
}

/// Tabs until keyboard focus reaches [label].
Future<void> _focus(PanelDriver panel, String label) async {
  for (var tab = 0; tab < 20 && !panel.hasFocusOn(label); tab++) {
    await panel.press(LogicalKeyboardKey.tab);
  }
  expect(panel.hasFocusOn(label), isTrue, reason: "$label takes focus");
}
