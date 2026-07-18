import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/app/presentation/theme/theme.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_controller.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_layout.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_placement.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_viewport.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_style.dart";

TimelineDsl timeline() => TimelineDsl();

class TimelineDsl {
  final List<TimelineTrack> _tracks = [];

  TimelineDsl track({required List<TimelineElementDsl> elements, String? id}) {
    _tracks.add(
      TimelineTrack(
        id: TimelineIdentifier(id ?? "track_${_tracks.length}"),
        header: (_) => const SizedBox.shrink(),
        elements: elements.map((e) => e.build(null)).toList(),
      ),
    );
    return this;
  }

  TimelineData build() {
    return TimelineData(tracks: _tracks);
  }
}

abstract class TimelineElementDsl {
  const TimelineElementDsl._();

  factory TimelineElementDsl.keyframe(String id, int frame) =
      _TimelineKeyframeDsl;

  factory TimelineElementDsl.segment(
    String id,
    int startFrame,
    int endFrame, [
    List<TimelineElementDsl> children,
  ]) = _TimelineSegmentDsl;

  TimelineElement build(String? parentId);
}

class _TimelineKeyframeDsl extends TimelineElementDsl {
  _TimelineKeyframeDsl(this.id, this.frame) : super._();

  final String id;
  final int frame;

  @override
  TimelineElement build(String? parentId) {
    return TimelineKeyframe(
      id: TimelineIdentifier(id),
      frame: frame,
      parentId: parentId != null ? TimelineIdentifier(parentId) : null,
      builder: (_, _) => const SizedBox.shrink(),
      color: Colors.orange,
    );
  }
}

class _TimelineSegmentDsl extends TimelineElementDsl {
  _TimelineSegmentDsl(
    this.id,
    this.startFrame,
    this.endFrame, [
    this.children = const [],
  ]) : super._();

  final String id;
  final int startFrame;
  final int endFrame;
  final List<TimelineElementDsl> children;

  @override
  TimelineElement build(String? parentId) {
    return TimelineSegment(
      id: TimelineIdentifier(id),
      startFrame: startFrame,
      endFrame: endFrame,
      parentId: parentId != null ? TimelineIdentifier(parentId) : null,
      children: children.map((e) => e.build(id)).toList(),
      builder: (_, _) => const SizedBox.shrink(),
      color: Colors.blue,
    );
  }
}

extension TimelineDataExtension on TimelineData {
  TimelineLayoutResult layout({List<TimelinePreview> previews = const []}) {
    return const TimelineLayoutEngine().build(data: this, previews: previews);
  }

  TimelineElement element(String id) {
    final timelineId = TimelineIdentifier(id);
    assert(elementsById.containsKey(timelineId), "Element $id not found");
    return elementsById[timelineId]!;
  }

  TimelinePreview move(String id, int frame) {
    final timelineId = TimelineIdentifier(id);
    final e = element(id);
    final preview = movePreview(timelineId)!;
    return preview.update(frame - e.startFrame);
  }

  TimelinePreview resizeStart(String id, int frame) {
    final timelineId = TimelineIdentifier(id);
    final e = element(id);
    assert(e is TimelineSegment, "Element $id is not a segment");
    final preview = resizeStartPreview(timelineId)!;
    return preview.update(frame - e.startFrame);
  }

  TimelinePreview resizeEnd(String id, int frame) {
    final timelineId = TimelineIdentifier(id);
    final e = element(id);
    assert(e is TimelineSegment, "Element $id is not a segment");
    final preview = resizeEndPreview(timelineId)!;
    return preview.update(frame - e.endFrame);
  }
}

extension TimelineLayoutResultExtension on TimelineLayoutResult {
  TimelinePlacementResult placement({
    TimelineViewport viewport = defaultTimelineViewport,
    TimelineStyle? style,
  }) {
    return const TimelinePlacementEngine().build(
      layout: this,
      viewport: viewport,
      style: style ?? TimelineStyle.fallback(buildTheme(Brightness.light)),
    );
  }
}

extension TimelinePlacementResultExtension on TimelinePlacementResult {
  TimelinePlacedElement element(String id) {
    final timelineId = TimelineIdentifier(id);
    assert(placementById.containsKey(timelineId), "Element $id not found");
    return placementById[timelineId]!;
  }
}

const defaultTimelineViewport = TimelineViewport(
  headerWidth: 200,
  planeWidth: 1200,
  planeHeight: 800,
  horizontalOffset: 0,
  verticalOffset: 0,
  pixelsPerFrame: 10,
  overscanFrames: 0,
);

TimelinePreviewCueDsl previewCue(String id) {
  return TimelinePreviewCueDsl(id);
}

class TimelinePreviewCueDsl {
  const TimelinePreviewCueDsl(this.id);

  final String id;

  TimelinePreview move({
    required int startFrame,
    required int endFrame,
    int? originalStartFrame,
    int? originalEndFrame,
  }) {
    return MoveTimelinePreview(
      id: TimelineIdentifier(id),
      startFrame: startFrame,
      endFrame: endFrame,
      originalStartFrame: originalStartFrame ?? startFrame,
      originalEndFrame: originalEndFrame ?? endFrame,
      frameRange: const FrameRange(
        FrameConstraint.infinite(),
        FrameConstraint.infinite(),
      ),
    );
  }

  TimelinePreview resizeStart({
    required int startFrame,
    required int endFrame,
    int? originalStartFrame,
  }) {
    return ResizeStartTimelinePreview(
      id: TimelineIdentifier(id),
      startFrame: startFrame,
      endFrame: endFrame,
      originalStartFrame: originalStartFrame ?? startFrame,
      startFrameRange: FrameRange(
        const FrameConstraint.infinite(),
        FrameConstraint.exact(endFrame),
      ),
    );
  }

  TimelinePreview resizeEnd({
    required int startFrame,
    required int endFrame,
    int? originalEndFrame,
  }) {
    return ResizeEndTimelinePreview(
      id: TimelineIdentifier(id),
      startFrame: startFrame,
      endFrame: endFrame,
      originalEndFrame: originalEndFrame ?? endFrame,
      endFrameRange: FrameRange(
        FrameConstraint.exact(startFrame),
        const FrameConstraint.infinite(),
      ),
    );
  }
}

void expectLaneIndices(
  TimelinePlacementResult layout,
  Map<String, int> expected,
) {
  final actual = <String, int>{
    for (final key in expected.keys) key: layout.element(key).laneIndex,
  };
  for (final entry in expected.entries) {
    expect(
      actual[entry.key],
      entry.value,
      reason: "${entry.key} actual: $actual",
    );
  }
}

void expectLaneIndicesMatch(
  TimelinePlacementResult left,
  TimelinePlacementResult right,
  List<String> ids,
) {
  for (final id in ids) {
    expect(left.element(id).laneIndex, right.element(id).laneIndex, reason: id);
  }
}

void expectContainmentInLayout(
  TimelinePlacementResult layout,
  TimelineData data,
) {
  for (final track in data.tracks) {
    for (final root in track.elements) {
      final placedRoot = layout.element(root.id.id);
      _expectContainedElement(placedRoot.element, parentAbsoluteStartFrame: 0);
    }
  }
}

void _expectContainedElement(
  TimelineElement element, {
  required int parentAbsoluteStartFrame,
}) {
  if (element is! TimelineSegment) return;

  final elementAbsoluteStart = parentAbsoluteStartFrame + element.startFrame;
  final elementAbsoluteEnd = parentAbsoluteStartFrame + element.endFrame;

  for (final child in element.children) {
    final childAbsoluteStart = elementAbsoluteStart + child.startFrame;
    final childAbsoluteEnd = elementAbsoluteStart + child.endFrame;

    expect(
      childAbsoluteStart,
      greaterThanOrEqualTo(elementAbsoluteStart),
      reason:
          "${child.id.id} starts before parent ${element.id.id} ($childAbsoluteStart < $elementAbsoluteStart)",
    );
    expect(
      childAbsoluteEnd,
      lessThanOrEqualTo(elementAbsoluteEnd),
      reason:
          "${child.id.id} ends after parent ${element.id.id} ($childAbsoluteEnd > $elementAbsoluteEnd)",
    );
    _expectContainedElement(
      child,
      parentAbsoluteStartFrame: elementAbsoluteStart,
    );
  }
}
