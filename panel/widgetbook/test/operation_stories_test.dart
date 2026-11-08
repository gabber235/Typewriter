import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/selectables/operations/open_operation.stories.dart";
import "package:widgetbook_workspace/stories/shared/selectables/operations/unbind_operation.stories.dart";

import "support/stories.dart";

void main() {
  final stories = {
    "Open": openOperationUseCase,
    "Unbind": unbindOperationUseCase,
  };
  for (final MapEntry(key: label, value: story) in stories.entries) {
    testWidgets("the inspector offers $label for the selected resources", (
      tester,
    ) async {
      final panel = await tester.pumpStory(story);

      expect(panel.inspector.operations, contains(startsWith(label)));
    });
  }

  testWidgets("an unbind that one resource refuses jams Unbind with why", (
    tester,
  ) async {
    const line = "Unbind 2 services? They disconnect straight away.";
    final panel = await tester.pumpStory(
      unbindOperationUseCase,
      knobs: {"Selected resources": "2", "Outcome": "Partly Fails"},
    );

    await panel.holdButton(line);

    // Meet the Mayor unbound and left the selection; Village Market stays.
    await panel.eventually(
      () => expect(
        panel.refusalOn("Unbind this service?"),
        "Village Market is still used by another page",
      ),
    );
  });
}
