import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/selectables/operations/delete_operation.stories.dart";
import "package:widgetbook_workspace/stories/shared/selectables/operations/open_operation.stories.dart";
import "package:widgetbook_workspace/stories/shared/selectables/operations/unbind_operation.stories.dart";

import "support/stories.dart";

void main() {
  final stories = {
    "Delete": deleteOperationUseCase,
    "Open": openOperationUseCase,
    "Unbind": unbindOperationUseCase,
  };
  for (final MapEntry(key: label, value: story) in stories.entries) {
    testWidgets("the inspector offers $label for the selected resources", (
      tester,
    ) async {
      final panel = await tester.pumpStory(story);

      // A button with a shortcut reads its key after its name.
      expect(panel.inspector.operations, contains(startsWith(label)));
    });
  }

  testWidgets("a delete that one resource refuses says which and why", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      deleteOperationUseCase,
      knobs: {"Selected resources": "2", "Outcome": "Partly Fails"},
    );

    // The open confirmation keeps animating, so the steps run frames
    // instead of settling.
    await tester.tap(find.text("Delete (2)"));
    await tester.runStory();
    expect(panel.shows("Delete 2 item(s)?"), isTrue);
    await tester.tap(find.text("Delete").last);
    await tester.runStory();

    expect(
      find.textContaining("Village Market is still used by another page"),
      findsWidgets,
    );
  });
}
