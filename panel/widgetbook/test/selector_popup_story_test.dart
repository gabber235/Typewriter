import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/selectables/presentation/selector_popup.stories.dart";

import "support/stories.dart";

void main() {
  final stories = {
    "Searchable sections": selectorPopupUseCase,
    "Current selection": selectorPopupWithSelectionUseCase,
  };
  for (final MapEntry(key: name, value: story) in stories.entries) {
    testWidgets("$name searches by section and the button shows the chosen "
        "book", (tester) async {
      final panel = await tester.pumpStory(story);

      await panel.tapOn(find.text("The lost lantern"));
      expect(panel.shows("MAIN STORY"), isTrue);
      expect(panel.shows("SIDE QUESTS"), isTrue);

      await tester.typeInStory("Search books", "merchant");
      expect(panel.shows("MAIN STORY"), isFalse);
      expect(panel.shows("Fishing contest"), isFalse);

      await panel.tapOn(find.text("The wandering merchant"));
      expect(panel.shows("SIDE QUESTS"), isFalse);
      expect(panel.shows("The wandering merchant"), isTrue);
      expect(panel.shows("The lost lantern"), isFalse);
    });
  }

  testWidgets("the selector opens from the keyboard", (tester) async {
    final panel = await tester.pumpStory(selectorPopupUseCase);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    expect(panel.shows("MAIN STORY"), isTrue);
  });

  testWidgets("a search without matches says so", (tester) async {
    final panel = await tester.pumpStory(selectorPopupUseCase);

    await panel.tapOn(find.text("The lost lantern"));
    await tester.typeInStory("Search books", "dragon");

    expect(panel.shows("No books match"), isTrue);
  });

  testWidgets("loading and failing choices offer no books, and only a "
      "failure says why", (tester) async {
    final failed = await tester.pumpStory(
      selectorPopupUseCase,
      knobs: {"Choices": "failed"},
    );
    expect(find.textContaining("did not return its books"), findsOneWidget);
    expect(failed.shows("The lost lantern"), isFalse);

    final loading = await tester.pumpStory(
      selectorPopupUseCase,
      knobs: {"Choices": "loading"},
    );
    expect(loading.shows("The lost lantern"), isFalse);
    expect(find.textContaining("did not return its books"), findsNothing);
  });
}
