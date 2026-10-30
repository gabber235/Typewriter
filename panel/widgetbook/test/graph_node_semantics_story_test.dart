import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/resource_drop_target.stories.dart";

import "support/stories.dart";

void main() {
  for (final nodes in ["Wide", "Narrow"]) {
    testWidgets("${nodes.toLowerCase()} entry nodes are each announced by "
        "their name once", (tester) async {
      await tester.pumpStory(resourceDropTargetStory, knobs: {"Nodes": nodes});

      for (final name in ["Welcome to the village", "Meet the village guide"]) {
        expect(find.semantics.byLabel(name), findsOne, reason: name);
      }
    });
  }
}
