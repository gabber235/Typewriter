import "dart:math" as math;

import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_cue_graph.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";

class SceneResolvedCueFrames {
  const SceneResolvedCueFrames({
    required this.localStartFrame,
    required this.localEndFrame,
    required this.absoluteStartFrame,
    required this.absoluteEndFrame,
  });

  final int localStartFrame;
  final int localEndFrame;
  final int absoluteStartFrame;
  final int absoluteEndFrame;
}

class SceneParentInfo {
  const SceneParentInfo({required this.startFrame, this.duration});

  final int startFrame;
  final int? duration;
}

SceneResolvedCueFrames resolveSceneCueFrames({
  required String cueId,
  required int absoluteStartFrame,
  required int absoluteEndFrame,
  required SceneCueGraphIndex index,
  required SceneParentInfo? parentInfo,
  required TimelineInteractionMode mode,
}) {
  final cue = index.cuesById[cueId];
  if (cue == null) {
    return SceneResolvedCueFrames(
      localStartFrame: absoluteStartFrame,
      localEndFrame: absoluteEndFrame,
      absoluteStartFrame: absoluteStartFrame,
      absoluteEndFrame: absoluteEndFrame,
    );
  }

  final isRoot = parentInfo == null;
  final parentStartFrame = parentInfo?.startFrame ?? 0;

  switch (mode) {
    case TimelineInteractionMode.move:
      if (isRoot) {
        return SceneResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final desiredLocalStart = absoluteStartFrame - parentStartFrame;
      final duration = absoluteEndFrame - absoluteStartFrame;
      final maxLocalStart = parentInfo.duration != null
          ? math.max(0, parentInfo.duration! - duration)
          : desiredLocalStart;
      final resolvedLocalStart = desiredLocalStart
          .clamp(0, math.max(0, maxLocalStart))
          .toInt();

      return SceneResolvedCueFrames(
        localStartFrame: resolvedLocalStart,
        localEndFrame: resolvedLocalStart + duration,
        absoluteStartFrame: parentStartFrame + resolvedLocalStart,
        absoluteEndFrame: parentStartFrame + resolvedLocalStart + duration,
      );

    case TimelineInteractionMode.resizeStart:
      if (cue is! Segment) {
        return SceneResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final baseLocalEnd = cue.endFrame;

      if (isRoot) {
        final newDuration = absoluteEndFrame - absoluteStartFrame;
        final newLocalStart = baseLocalEnd - newDuration;
        return SceneResolvedCueFrames(
          localStartFrame: newLocalStart.clamp(0, baseLocalEnd),
          localEndFrame: baseLocalEnd,
          absoluteStartFrame: newLocalStart.clamp(0, baseLocalEnd),
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final requiredDuration = _requiredDurationForChildren(cueId, index);
      final maxStart = baseLocalEnd - requiredDuration;
      final newLocalStart = absoluteStartFrame - parentStartFrame;
      final clampedLocalStart = newLocalStart
          .clamp(0, math.max(0, maxStart))
          .toInt();

      return SceneResolvedCueFrames(
        localStartFrame: clampedLocalStart,
        localEndFrame: baseLocalEnd,
        absoluteStartFrame: parentStartFrame + clampedLocalStart,
        absoluteEndFrame: absoluteEndFrame,
      );

    case TimelineInteractionMode.resizeEnd:
      if (cue is! Segment) {
        return SceneResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final baseLocalStart = cue.startFrame;

      if (isRoot) {
        return SceneResolvedCueFrames(
          localStartFrame: baseLocalStart,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final minEnd =
          baseLocalStart + _requiredDurationForChildren(cueId, index);
      final maxEnd = parentInfo.duration ?? absoluteEndFrame;
      final newLocalEnd = (absoluteEndFrame - parentStartFrame).clamp(
        minEnd,
        maxEnd,
      );

      return SceneResolvedCueFrames(
        localStartFrame: baseLocalStart,
        localEndFrame: newLocalEnd,
        absoluteStartFrame: absoluteStartFrame,
        absoluteEndFrame: parentStartFrame + newLocalEnd,
      );
  }
}

SceneParentInfo? findSceneParentInfo(String cueId, SceneCueGraphIndex index) {
  final parentCueId = index.parentByCueId[cueId];
  if (parentCueId == null) return null;

  final parentCue = index.cuesById[parentCueId];
  if (parentCue == null) return null;

  final parentStartFrame = switch (parentCue) {
    Segment(startFrame: final startFrame) => startFrame,
    Keyframe(frame: final frame) => frame,
    _ => 0,
  };

  final parentDuration = switch (parentCue) {
    Segment(startFrame: final start, endFrame: final end) => end - start,
    Keyframe() => null,
    _ => null,
  };

  return SceneParentInfo(
    startFrame: parentStartFrame,
    duration: parentDuration,
  );
}

int absoluteFrameFromLocalFrame(
  int localFrame,
  String cueId,
  SceneCueGraphIndex index,
) {
  var currentCueId = cueId;
  var absoluteOffset = localFrame;

  while (true) {
    final parentCueId = index.parentByCueId[currentCueId];
    if (parentCueId == null) break;

    final parentCue = index.cuesById[parentCueId];
    if (parentCue == null) break;

    final parentStartFrame = switch (parentCue) {
      Segment(startFrame: final startFrame) => startFrame,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };

    absoluteOffset += parentStartFrame;
    currentCueId = parentCueId;
  }

  return absoluteOffset;
}

int _requiredDurationForChildren(String cueId, SceneCueGraphIndex index) {
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
