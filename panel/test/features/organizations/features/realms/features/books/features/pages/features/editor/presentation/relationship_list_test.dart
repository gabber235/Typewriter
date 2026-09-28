import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("expands a resource and activates its exact usage", (
    tester,
  ) async {
    RelationshipUsage? opened;
    DataPath? focused;
    final usage = RelationshipUsage(
      sourceId: "source",
      targetId: "target",
      slot: ".success",
      sourcePath: DataPath.root.field("success"),
    );
    await tester.pumpTestApp(
      child: RelationshipList(
        relationships: EntryRelationships(
          incoming: [
            RelationshipGroup(
              resourceId: "source",
              name: "Source",
              pageId: "page",
              usages: [usage],
            ),
          ],
          outgoing: const [],
        ),
        onOpenResource: (_) {},
        onOpenUsage: (_, value) => opened = value,
        onFocusSourceField: (_, path) => focused = path,
      ),
    );

    await tester.tap(find.text("Source"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(".success"));
    await tester.pumpAndSettle();

    expect(opened, usage);
    expect(focused, DataPath.root.field("success"));
  });
}
