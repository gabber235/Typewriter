import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/entries.dart";

/// Creates a stable timeline document whose shape is controlled independently
/// along each useful dimension.
List<PageElement> generateTimelinePageElements({
  required int trackCount,
  required int segmentsPerTrack,
  required int keyframesPerSegment,
  required int nestingDepth,
}) {
  assert(trackCount >= 0);
  assert(segmentsPerTrack >= 0);
  assert(keyframesPerSegment >= 0);
  assert(nestingDepth >= 0);

  final elements = <PageElement>[];
  for (var trackIndex = 0; trackIndex < trackCount; trackIndex++) {
    final trackId = "timeline_track_$trackIndex";
    final outward = <ElementLink>[];
    final cues = <PageElement>[];
    for (
      var segmentIndex = 0;
      segmentIndex < segmentsPerTrack;
      segmentIndex++
    ) {
      final segmentId = "${trackId}_segment_$segmentIndex";
      final linkId = "$trackId->$segmentId";
      outward.add(
        ElementLink(linkId: linkId, otherId: segmentId, path: "children"),
      );
      _appendSegment(
        cues,
        id: segmentId,
        parentId: trackId,
        parentLinkId: linkId,
        startFrame: segmentIndex * 60,
        endFrame: segmentIndex * 60 + 50,
        depth: 0,
        maximumDepth: nestingDepth,
        keyframeCount: keyframesPerSegment,
      );
    }

    final definition = EntryDefinition(
      id: trackId,
      name: "Timeline Track ${trackIndex + 1}",
      elementDefinition: _definition(
        id: "track_$trackIndex",
        name: "Timeline Track",
        icon: "solar:video-frame-bold",
        colorIndex: trackIndex,
      ),
      placement: EntryPlacement(
        x: trackIndex,
        y: 0,
        width: 1,
        height: 1,
        kind: EntryPlacementKind.timelineEntry,
      ),
      data: RecordValue({"label": StringValue("Track ${trackIndex + 1}")}),
      inwardEdges: const [],
      outwardEdges: outward,
    );
    elements
      ..add(
        PageElement.entry(entry: PageEntry.definition(definition: definition)),
      )
      ..addAll(cues);
  }
  return elements;
}

void _appendSegment(
  List<PageElement> elements, {
  required String id,
  required String parentId,
  required String parentLinkId,
  required int startFrame,
  required int endFrame,
  required int depth,
  required int maximumDepth,
  required int keyframeCount,
}) {
  final outward = <ElementLink>[];
  if (depth < maximumDepth) {
    final childId = "${id}_nested";
    final linkId = "$id->$childId";
    outward.add(
      ElementLink(linkId: linkId, otherId: childId, path: "children"),
    );
  }
  for (var index = 0; index < keyframeCount; index++) {
    final keyframeId = "${id}_keyframe_$index";
    outward.add(
      ElementLink(
        linkId: "$id->$keyframeId",
        otherId: keyframeId,
        path: "children",
      ),
    );
  }

  elements.add(
    PageElement.cue(
      cue: Cue.segment(
        id: id,
        elementDefinition: _definition(
          id: "segment_$depth",
          name: "Timeline Segment ${depth + 1}",
          icon: "fa-solid:video",
          colorIndex: depth + 1,
        ),
        startFrame: startFrame,
        endFrame: endFrame,
        data: RecordValue({"label": StringValue("Segment ${depth + 1}")}),
        inwardLinks: [
          ElementLink(linkId: parentLinkId, otherId: parentId, path: "parent"),
        ],
        outwardLinks: outward,
      ),
    ),
  );

  final duration = endFrame - startFrame;
  if (depth < maximumDepth) {
    final childId = "${id}_nested";
    _appendSegment(
      elements,
      id: childId,
      parentId: id,
      parentLinkId: "$id->$childId",
      startFrame: 5,
      endFrame: duration - 5,
      depth: depth + 1,
      maximumDepth: maximumDepth,
      keyframeCount: keyframeCount,
    );
  }
  for (var index = 0; index < keyframeCount; index++) {
    final keyframeId = "${id}_keyframe_$index";
    elements.add(
      PageElement.cue(
        cue: Cue.keyframe(
          id: keyframeId,
          elementDefinition: _definition(
            id: "keyframe_$index",
            name: "Timeline Keyframe",
            icon: "fa7-solid:star",
            colorIndex: index + depth + 2,
          ),
          frame: ((index + 1) * duration) ~/ (keyframeCount + 1),
          data: RecordValue({"label": StringValue("Keyframe ${index + 1}")}),
          inwardLinks: [
            ElementLink(
              linkId: "$id->$keyframeId",
              otherId: id,
              path: "parent",
            ),
          ],
        ),
      ),
    );
  }
}

ElementDefinition _definition({
  required String id,
  required String name,
  required String icon,
  required int colorIndex,
}) => ElementDefinition(
  rootType: ResolvedTypeRef(
    id: fixtureDeclaredTypeId("timeline:$id"),
    revision: 1,
  ),
  name: name,
  description: "$name fixture",
  color: safeColors[colorIndex % safeColors.length],
  icon: IconValue.iconify(icon),
);
