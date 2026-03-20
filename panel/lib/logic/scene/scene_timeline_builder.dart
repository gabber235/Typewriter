import "dart:math" as math;

import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_cue_index.dart";
import "package:typewriter_panel/logic/scene/scene_identifier.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_data.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_track.dart";

SceneTimelineData buildSceneTimelineData(
  List<PageElement> elements, {
  SceneTimelineOverride? override,
}) {
  final index = SceneCueIndex.fromPageElements(elements);
  final tracks = [
    for (final entry in index.entries)
      SceneTimelineTrack(
        id: SceneIdentifier(entry.id),
        entryId: entry.id,
        rootItems: _buildTrackItems(
          rootCueIds: index.rootCueIdsByEntryId[entry.id] ?? const <String>[],
          index: index,
          override: override,
        ),
      ),
  ];

  return SceneTimelineData(tracks: tracks);
}

class SceneTimelineOverride {
  const SceneTimelineOverride({
    required this.cueId,
    required this.mode,
    required this.startFrame,
    required this.endFrame,
  });

  final String cueId;
  final SceneTimelineOverrideMode mode;
  final int startFrame;
  final int endFrame;
}

enum SceneTimelineOverrideMode { move, resizeStart, resizeEnd }

List<SceneTimelineItem> _buildTrackItems({
  required List<String> rootCueIds,
  required SceneCueIndex index,
  required SceneTimelineOverride? override,
}) {
  final items = <SceneTimelineItem>[];
  final activeCueIds = <String>{};

  for (final rootCueId in rootCueIds) {
    final cue = index.cuesById[rootCueId];
    assert(cue != null, "Missing root cue $rootCueId for scene track.");
    if (cue == null) continue;

    items.add(
      _buildCueItem(
        cueId: rootCueId,
        index: index,
        activeCueIds: activeCueIds,
        override: override,
        depth: 0,
      ),
    );
  }

  items.sort();
  return items;
}

SceneTimelineItem _buildCueItem({
  required String cueId,
  required SceneCueIndex index,
  required Set<String> activeCueIds,
  required SceneTimelineOverride? override,
  required int depth,
  String? parentCueId,
  int parentAbsoluteStartFrame = 0,
  int? parentDuration,
}) {
  assert(!activeCueIds.contains(cueId), "Scene cue cycle detected at $cueId.");

  final cue = index.cuesById[cueId];
  assert(cue != null, "Missing cue $cueId in scene index.");
  if (cue == null) throw StateError("Missing cue $cueId in scene index.");

  return switch (cue) {
    Segment(startFrame: final startFrame, endFrame: final endFrame) =>
      _buildSegmentItem(
        cueId: cueId,
        localStartFrame: startFrame,
        localEndFrame: endFrame,
        index: index,
        activeCueIds: activeCueIds,
        override: override,
        depth: depth,
        parentCueId: parentCueId,
        parentAbsoluteStartFrame: parentAbsoluteStartFrame,
        parentDuration: parentDuration,
      ),
    Keyframe(frame: final frame) => _buildKeyframeItem(
      cueId: cueId,
      localFrame: frame,
      override: override,
      depth: depth,
      parentCueId: parentCueId,
      parentAbsoluteStartFrame: parentAbsoluteStartFrame,
      parentDuration: parentDuration,
    ),
    _ => throw StateError("Unknown cue type"),
  };
}

SceneSegmentItem _buildSegmentItem({
  required String cueId,
  required int localStartFrame,
  required int localEndFrame,
  required SceneCueIndex index,
  required Set<String> activeCueIds,
  required SceneTimelineOverride? override,
  required int depth,
  required String? parentCueId,
  required int parentAbsoluteStartFrame,
  required int? parentDuration,
}) {
  activeCueIds.add(cueId);

  try {
    final requiredDuration = _requiredDurationForChildren(cueId, index);
    final resolved = _resolveSegmentFrames(
      cueId: cueId,
      localStartFrame: localStartFrame,
      localEndFrame: localEndFrame,
      requiredDuration: requiredDuration,
      override: override,
      parentAbsoluteStartFrame: parentAbsoluteStartFrame,
      parentDuration: parentDuration,
    );

    final children = <SceneTimelineItem>[];

    for (final childCueId in index.childrenByCueId[cueId] ?? const <String>[]) {
      final childCue = index.cuesById[childCueId];
      assert(
        childCue != null,
        "Missing child cue $childCueId for parent $cueId.",
      );
      if (childCue == null) continue;

      assert(
        index.parentByCueId[childCueId] == cueId,
        "Cue $childCueId is not parented by $cueId in scene data.",
      );

      children.add(
        _buildCueItem(
          cueId: childCueId,
          index: index,
          activeCueIds: activeCueIds,
          override: override,
          depth: depth + 1,
          parentCueId: cueId,
          parentAbsoluteStartFrame: resolved.absoluteStartFrame,
          parentDuration: resolved.duration,
        ),
      );
    }

    children.sort();

    return SceneSegmentItem(
      id: SceneIdentifier(cueId),
      cueId: cueId,
      parentCueId: parentCueId,
      localStartFrame: resolved.localStartFrame,
      localEndFrame: resolved.localEndFrame,
      absoluteStartFrame: resolved.absoluteStartFrame,
      absoluteEndFrame: resolved.absoluteEndFrame,
      depth: depth,
      requiredDuration: requiredDuration,
      children: children,
    );
  } finally {
    activeCueIds.remove(cueId);
  }
}

SceneKeyframeItem _buildKeyframeItem({
  required String cueId,
  required int localFrame,
  required SceneTimelineOverride? override,
  required int depth,
  required String? parentCueId,
  required int parentAbsoluteStartFrame,
  required int? parentDuration,
}) {
  var resolvedLocalFrame = localFrame;

  if (override?.cueId == cueId) {
    final desiredLocalFrame = override!.startFrame - parentAbsoluteStartFrame;
    final maxFrame = parentDuration == null
        ? desiredLocalFrame
        : math.max(0, parentDuration);
    resolvedLocalFrame = desiredLocalFrame.clamp(0, math.max(0, maxFrame));
  }

  final absoluteFrame = parentCueId == null
      ? resolvedLocalFrame
      : parentAbsoluteStartFrame + resolvedLocalFrame;

  return SceneKeyframeItem(
    id: SceneIdentifier(cueId),
    cueId: cueId,
    parentCueId: parentCueId,
    localStartFrame: resolvedLocalFrame,
    absoluteStartFrame: absoluteFrame,
    depth: depth,
  );
}

int _requiredDurationForChildren(String cueId, SceneCueIndex index) {
  var requiredDuration = 0;

  for (final childCueId in index.childrenByCueId[cueId] ?? const <String>[]) {
    final childCue = index.cuesById[childCueId];
    if (childCue == null) continue;

    final childEndFrame = switch (childCue) {
      Segment(endFrame: final endFrame) => endFrame,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };
    requiredDuration = math.max(requiredDuration, childEndFrame);
  }

  return requiredDuration;
}

_ResolvedSegmentFrames _resolveSegmentFrames({
  required String cueId,
  required int localStartFrame,
  required int localEndFrame,
  required int requiredDuration,
  required SceneTimelineOverride? override,
  required int parentAbsoluteStartFrame,
  required int? parentDuration,
}) {
  var resolvedLocalStartFrame = localStartFrame;
  var resolvedLocalEndFrame = localEndFrame;
  final duration = localEndFrame - localStartFrame;

  if (override?.cueId == cueId) {
    switch (override!.mode) {
      case SceneTimelineOverrideMode.move:
        final desiredLocalStartFrame =
            override.startFrame - parentAbsoluteStartFrame;
        final maxStartFrame = parentDuration == null
            ? desiredLocalStartFrame
            : math.max(0, parentDuration - duration);
        resolvedLocalStartFrame = desiredLocalStartFrame.clamp(
          0,
          math.max(0, maxStartFrame),
        );
        resolvedLocalEndFrame = resolvedLocalStartFrame + duration;
      case SceneTimelineOverrideMode.resizeStart:
        final desiredLocalStartFrame =
            override.startFrame - parentAbsoluteStartFrame;
        final maxStartFrame = math.min(
          resolvedLocalEndFrame,
          resolvedLocalEndFrame - requiredDuration,
        );
        resolvedLocalStartFrame = desiredLocalStartFrame.clamp(
          0,
          math.max(0, maxStartFrame),
        );
      case SceneTimelineOverrideMode.resizeEnd:
        final desiredLocalEndFrame =
            override.endFrame - parentAbsoluteStartFrame;
        final minEndFrame = resolvedLocalStartFrame + requiredDuration;
        final maxEndFrame = parentDuration == null
            ? math.max(minEndFrame, desiredLocalEndFrame)
            : math.max(minEndFrame, parentDuration);
        resolvedLocalEndFrame = desiredLocalEndFrame.clamp(
          minEndFrame,
          maxEndFrame,
        );
    }
  }

  final absoluteStartFrame = parentDuration == null
      ? resolvedLocalStartFrame
      : parentAbsoluteStartFrame + resolvedLocalStartFrame;
  final absoluteEndFrame = parentDuration == null
      ? resolvedLocalEndFrame
      : parentAbsoluteStartFrame + resolvedLocalEndFrame;

  return _ResolvedSegmentFrames(
    localStartFrame: resolvedLocalStartFrame,
    localEndFrame: resolvedLocalEndFrame,
    absoluteStartFrame: absoluteStartFrame,
    absoluteEndFrame: absoluteEndFrame,
  );
}

class _ResolvedSegmentFrames {
  const _ResolvedSegmentFrames({
    required this.localStartFrame,
    required this.localEndFrame,
    required this.absoluteStartFrame,
    required this.absoluteEndFrame,
  });

  final int localStartFrame;
  final int localEndFrame;
  final int absoluteStartFrame;
  final int absoluteEndFrame;

  int get duration => localEndFrame - localStartFrame;
}
