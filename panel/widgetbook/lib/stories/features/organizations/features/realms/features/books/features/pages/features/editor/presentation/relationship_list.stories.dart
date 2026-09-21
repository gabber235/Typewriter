import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Grouped usages", type: RelationshipList)
Widget relationshipListStory(BuildContext context) => FakeApp(
  child: Scaffold(
    body: Center(
      child: SizedBox(
        width: 420,
        child: RelationshipList(
          relationships: _relationships,
          onOpenResource: (_) {},
          onOpenUsage: (_, _) {},
          onFocusSourceField: (_, _) {},
        ),
      ),
    ),
  ),
);

final _relationships = EntryRelationships(
  incoming: [
    RelationshipGroup(
      resourceId: "source",
      name: "Quest source",
      pageId: "opening",
      usages: [
        RelationshipUsage(
          sourceId: "source",
          targetId: "selected",
          slot: ".fallback",
          sourcePath: DataPath.root.field("fallback"),
        ),
        RelationshipUsage(
          sourceId: "source",
          targetId: "selected",
          slot: ".success",
          sourcePath: DataPath.root.field("success"),
        ),
      ],
    ),
  ],
  outgoing: [
    RelationshipGroup(
      resourceId: "target",
      name: "Next dialogue",
      pageId: "closing",
      usages: [
        RelationshipUsage(
          sourceId: "selected",
          targetId: "target",
          slot: ".next",
          sourcePath: DataPath.root.field("next"),
        ),
      ],
    ),
  ],
);
