import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/features/organizations/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/shared/search/presentation/search_result_row.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets(
    "the catalog renders the organizations page with no organizations, "
    "though the story starts with a few",
    (tester) async {
      await tester.pumpStory(indexPageUseCase);

      final variants = storyVariants(tester.storyKnobs.values);

      expect(variants, contains(equals({"Organizations": "None"})));
      // The start state is the initial image; it is not rendered twice.
      expect(variants, isNot(contains(equals({"Organizations": "Few"}))));
    },
  );

  testWidgets("the catalog renders a loading search result row, "
      "though the story starts with Loading off", (tester) async {
    await tester.pumpStory(searchResultRowUseCase);

    final variants = storyVariants(tester.storyKnobs.values);

    expect(variants, contains(equals({"Loading": "true"})));
    expect(variants, isNot(contains(equals({"Loading": "false"}))));
  });
}
