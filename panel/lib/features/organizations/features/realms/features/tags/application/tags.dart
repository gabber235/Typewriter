import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";
part "tag_model.dart";

const tagGraphCellSize = 50.0;

RecordValue tagCreationPartial(
  Iterable<Tag> tags, {
  Offset? preferredGraphAnchor,
}) {
  final obstacles = [
    for (final tag in tags)
      GraphGridRect(
        x: tag.placement.x,
        y: tag.placement.y,
        width: tag.placement.width,
        height: tag.placement.height,
      ),
  ];
  final placement = const GraphIncrementalPlacer()
      .placeGroup(
        obstacles: obstacles,
        group: [GraphGridRect(x: 0, y: 0, width: 4, height: 1)],
        anchor:
            preferredGraphAnchor ??
            graphCenterOfMass(obstacles, cellSize: tagGraphCellSize) ??
            Offset.zero,
      )
      .single;
  return RecordValue({
    "placement": RecordValue({
      "x": placement.x.asValue,
      "y": placement.y.asValue,
      "width": placement.width.asValue,
      "height": placement.height.asValue,
    }),
  });
}

/// Typed tag views of the shared working document.
@riverpod
AsyncValue<List<Tag>> workingTags(Ref ref) {
  final source = ref.watch(selectedWorkingAuthoringDocumentProvider);
  if (source.mapUnready<List<Tag>>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.entries.values
        .where((entry) => entry.definition == coreTagResourceDefinition)
        .map(Tag.fromAuthoring)
        .toList(growable: false),
  );
}

@riverpod
AsyncValue<Tag?> workingTag(Ref ref, skir.ResourceId tagId) {
  final source = ref.watch(workingTagsProvider);
  if (source.mapUnready<Tag?>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.firstWhereOrNull((tag) => tag.tagId == tagId),
  );
}
