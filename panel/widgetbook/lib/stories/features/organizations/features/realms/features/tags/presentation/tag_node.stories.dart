import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/realm_runtime.dart";
import "package:widgetbook_workspace/support/selected_inspector_story.dart";

@widgetbook.UseCase(name: "Default", type: TagNode)
Widget tagNodeUseCase(BuildContext context) {
  final previewTag = Tag(
    tagId: recordId("tag:current_tag"),
    name: "current_tag",
    color: Colors.purple,
    parentIds: const [],
    placement: const Placement(x: 2, y: 3, width: 4, height: 1),
  );
  final parentCandidate = Tag(
    tagId: recordId("tag:candidate_parent"),
    name: "candidate_parent",
    color: Colors.teal,
    parentIds: const [],
    placement: const Placement(x: 8, y: 1, width: 4, height: 1),
  );

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(tags: [previewTag, parentCandidate]),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: [previewTag, parentCandidate]),
    ],
    child: InspectorScaffold(
      realmRuntime: storyRealmRuntime([previewTag, parentCandidate]),
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

@widgetbook.UseCase(name: "Mixed selection", type: TagNode)
Widget mixedTagSelectionUseCase(BuildContext context) =>
    mixedTagSelectionStory();

Widget mixedTagSelectionStory({bool initiallySelected = true}) {
  final earth = _storyTag("earth", color: Colors.blue, x: 0);
  final europe = _storyTag(
    "europe",
    color: Colors.indigo,
    parents: [earth.tagId],
    x: 4,
  );
  final netherlands = _storyTag(
    "netherlands",
    color: Colors.orange,
    parents: [europe.tagId],
    x: 8,
  );
  final italy = _storyTag(
    "italy",
    color: Colors.orange,
    parents: [earth.tagId],
    x: 12,
  );
  final tags = [earth, europe, netherlands, italy];
  final selected = [netherlands, italy];

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(tags: tags),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: tags),
    ],
    child: InspectorScaffold(
      realmRuntime: storyRealmRuntime(tags),
      child: SelectedInspectorStory(
        selection: initiallySelected
            ? [for (final tag in selected) TagIdentifier(tag.tagId)]
            : const [],
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final tag in tags)
                SizedBox(
                  width: 150,
                  height: 50,
                  child: TagNode(tagId: tag.tagId),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Tag _storyTag(
  String name, {
  required Color color,
  required int x,
  List<skir.RecordId> parents = const [],
}) => Tag(
  tagId: recordId("tag:$name"),
  name: name,
  color: color,
  parentIds: parents,
  placement: Placement(x: x, y: 0, width: 4, height: 1),
);

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
      name: "tag_${entry.key}",
      color: entry.value,
      parentIds: const [],
      placement: const Placement(x: 0, y: 0, width: 2, height: 1),
    );
  }).toList();

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(tags: tags),
      organizationIdProvider.overrideWithValue(
        recordId("organization:widgetbook"),
      ),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      ...tagsProviderOverrides(tags: tags),
    ],
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
