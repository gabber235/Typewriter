import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/authoring/search/presentation/authoring_search_result_items.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a Book result names its tags", (tester) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"Kind": "Book"},
    );

    expect(panel.shows("Main Quest"), isTrue);
    expect(panel.shows("Quest tag"), isTrue);
  });

  testWidgets("a Page result names its type, Book and chapter", (tester) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"Kind": "Page"},
    );

    expect(panel.shows("Meet the Mayor"), isTrue);
    expect(panel.shows("DIALOGUE PAGE"), isTrue);
    expect(panel.shows("Main Quest"), isTrue);
    expect(panel.shows("Village"), isTrue);
  });

  testWidgets("an Element result follows a renamed Book", (tester) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"Kind": "Element", "Book title": "The Coast"},
    );

    expect(panel.shows("Mayor greeting"), isTrue);
    expect(panel.shows("SPEAKER"), isTrue);
    expect(panel.shows("Meet the Mayor"), isTrue);
    expect(panel.shows("The Coast"), isTrue);
    expect(panel.shows("Main Quest"), isFalse);
  });

  testWidgets("opened from its Page, an Element result leaves out the "
      "location the user is already in", (tester) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"Kind": "Element", "Opened from": "The Page"},
    );

    expect(panel.shows("Mayor greeting"), isTrue);
    expect(panel.shows("Meet the Mayor"), isFalse);
    expect(panel.shows("Village"), isFalse);
  });

  testWidgets("a Book whose tag is gone says the tag is unavailable", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"Kind": "Book", "State": "Missing tag", "Width": "240"},
    );

    expect(panel.shows("Unavailable tag"), isTrue);
  });

  testWidgets("a removed resource keeps its row as unavailable", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"State": "Removed"},
    );

    expect(panel.shows("Removed resource"), isTrue);
    expect(panel.shows("UNAVAILABLE"), isTrue);
  });

  testWidgets("a result without one clear presentation says why", (
    tester,
  ) async {
    var panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"State": "Ambiguous presentation"},
    );
    expect(panel.shows("Meet the Mayor"), isTrue);
    expect(panel.shows("The search result presentation is ambiguous"), isTrue);

    panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {"State": "Unavailable presentation"},
    );
    expect(panel.shows("Meet the Mayor"), isTrue);
    expect(
      panel.shows("The search result presentation is unavailable"),
      isTrue,
    );
  });

  testWidgets("clicking a result selects it", (tester) async {
    final panel = await tester.pumpStory(
      authoringSearchResultUseCase,
      knobs: {},
    );
    final row = find.text("Meet the Mayor");
    expect(tester.getSemantics(row), isNot(isSemantics(isSelected: true)));

    await panel.tapOn(row);

    expect(tester.getSemantics(row), isSemantics(isSelected: true));
  });

  testWidgets("narrow compact results lay out every kind", (tester) async {
    for (final kind in ["Book", "Tag", "Page", "Element"]) {
      await tester.pumpStory(
        authoringSearchResultUseCase,
        knobs: {"Kind": kind, "Density": "compact", "Width": "240"},
      );
      expect(tester.takeException(), isNull, reason: kind);
    }
  });

  testWidgets("a creation result names the type and why it is unavailable", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoringCreationResultUseCase,
      knobs: {"Unavailable": "true"},
    );

    expect(panel.shows("Dialogue page"), isTrue);
    expect(panel.shows("The Realm is read only"), isTrue);
  });
}
