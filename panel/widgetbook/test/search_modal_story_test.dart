import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/search/presentation/search_modal.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a ready source lists its results once the search answers", (
    tester,
  ) async {
    final panel = await tester.pumpStory(searchModalDirectUseCase);

    expect(panel.search.result("Story book").isShown, isTrue);
    expect(panel.search.result("Quest").isShown, isTrue);
  });

  testWidgets("a failing source tells the user the search failed", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      searchModalDirectUseCase,
      knobs: {"Source state": "error"},
    );

    expect(panel.shows("Search source failed"), isTrue);
  });

  testWidgets("a source without data shows no results", (tester) async {
    final panel = await tester.pumpStory(
      searchModalDirectUseCase,
      knobs: {"Has data": "false"},
    );

    expect(panel.search.result("Story book").isShown, isFalse);
  });
}
