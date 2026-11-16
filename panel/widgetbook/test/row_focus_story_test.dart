import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/ui/row_focus.stories.dart";

import "support/stories.dart";

void main() {
  for (final layout in ["Table", "Cards", "Editor"]) {
    testWidgets("the $layout story opens on the first row and hands focus on "
        "after a remove and a create", (tester) async {
      final panel = await tester.pumpStory(
        rowFocusUseCase,
        knobs: {"Layout": layout},
      );
      expect(panel.focused, contains("Alpha"));

      await panel.tapOn(find.text("Remove focused"));
      expect(panel.focused, contains("Beta"));

      await panel.tapOn(find.text("Announce a create"));
      expect(panel.focused, contains("Row 1"));
    });
  }
}
