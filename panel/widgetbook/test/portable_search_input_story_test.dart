import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_search_input.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("choosing a reward from the search binds it as the value", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(authoredSearchInputUseCase))!;
    expect(panel.shows("Coin reward"), isTrue);

    // The summary shows the bound reward; tapping it opens the search.
    await tester.tapAt(tester.getCenter(find.text("Coin reward")));
    await tester.runStory();
    await tester.tapAt(tester.getCenter(find.text("Experience reward")));
    await tester.runStory();

    expect(panel.shows("Experience reward"), isTrue);
    expect(panel.shows("Coin reward"), isFalse);
  });

  testWidgets("a search without choices says nothing matches", (tester) async {
    final panel = (await tester.pumpStory(
      authoredSearchInputUseCase,
      knobs: {"Choices": "None"},
    ))!;

    // The summary shows the bound reward; tapping it opens the search.
    await tester.tapAt(tester.getCenter(find.text("Coin reward")));
    await tester.runStory();

    expect(panel.shows("No matching rewards"), isTrue);
  });
}
