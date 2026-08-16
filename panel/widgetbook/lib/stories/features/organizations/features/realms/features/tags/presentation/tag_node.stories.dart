import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: TagNode)
Widget tagNodeUseCase(BuildContext context) {
  final previewTag = Tag(
    tagId: recordId("tag:current_tag"),
    revision: 1,
    name: "current_tag",
    color: Colors.purple,
    parentIds: const [],
    placement: const Placement(x: 2, y: 3, width: 4, height: 1),
  );
  final parentCandidate = Tag(
    tagId: recordId("tag:candidate_parent"),
    revision: 1,
    name: "candidate_parent",
    color: Colors.teal,
    parentIds: const [],
    placement: const Placement(x: 8, y: 1, width: 4, height: 1),
  );

  return FakeApp(
    overrides: [
      ...tagsProviderOverrides(tags: [previewTag, parentCandidate]),
    ],
    child: InspectorScaffold(
      child: Center(
        child: SizedBox(
          width: 150,
          height: 50,
          child: TagNode(tagId: previewTag.tagId),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Multiple Colors", type: TagNode)
Widget tagNodeColorsUseCase(BuildContext context) {
  final colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  final tags = colors.asMap().entries.map((entry) {
    return Tag(
      tagId: recordId("tag:tag_${entry.key}"),
      revision: 1,
      name: "tag_${entry.key}",
      color: entry.value,
      parentIds: const [],
      placement: const Placement(x: 0, y: 0, width: 2, height: 1),
    );
  }).toList();

  return FakeApp(
    overrides: [...tagsProviderOverrides(tags: tags)],
    child: InspectorScaffold(
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tags.map((tag) {
            return SizedBox(
              width: 120,
              height: 40,
              child: TagNode(tagId: tag.tagId),
            );
          }).toList(),
        ),
      ),
    ),
  );
}
