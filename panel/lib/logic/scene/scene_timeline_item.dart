import "package:typewriter_panel/logic/scene/scene_identifier.dart";

sealed class SceneTimelineItem implements Comparable<SceneTimelineItem> {
  const SceneTimelineItem({
    required this.id,
    required this.cueId,
    required this.parentCueId,
    required this.localStartFrame,
    required this.absoluteStartFrame,
    required this.depth,
  });

  final SceneIdentifier id;
  final String cueId;
  final String? parentCueId;
  final int localStartFrame;
  final int absoluteStartFrame;
  final int depth;

  int get localEndFrame;

  int get absoluteEndFrame;

  bool containsCue(String otherCueId);

  @override
  int compareTo(SceneTimelineItem other) {
    final frameCompare = absoluteStartFrame.compareTo(other.absoluteStartFrame);
    if (frameCompare != 0) return frameCompare;

    final endCompare = other.absoluteEndFrame.compareTo(absoluteEndFrame);
    if (endCompare != 0) return endCompare;

    return switch ((this, other)) {
      (SceneSegmentItem(), SceneKeyframeItem()) => -1,
      (SceneKeyframeItem(), SceneSegmentItem()) => 1,
      _ => cueId.compareTo(other.cueId),
    };
  }
}

class SceneSegmentItem extends SceneTimelineItem {
  const SceneSegmentItem({
    required super.id,
    required super.cueId,
    required super.parentCueId,
    required super.localStartFrame,
    required this.localEndFrame,
    required super.absoluteStartFrame,
    required this.absoluteEndFrame,
    required super.depth,
    required this.requiredDuration,
    required this.children,
  }) : assert(localStartFrame >= 0),
       assert(localEndFrame >= 0),
       assert(localEndFrame >= localStartFrame),
       assert(absoluteStartFrame >= 0),
       assert(absoluteEndFrame >= absoluteStartFrame),
       assert(requiredDuration >= 0);

  @override
  final int localEndFrame;
  @override
  final int absoluteEndFrame;
  final int requiredDuration;
  final List<SceneTimelineItem> children;

  @override
  bool containsCue(String otherCueId) {
    if (cueId == otherCueId) return true;
    return children.any((child) => child.containsCue(otherCueId));
  }
}

class SceneKeyframeItem extends SceneTimelineItem {
  const SceneKeyframeItem({
    required super.id,
    required super.cueId,
    required super.parentCueId,
    required super.localStartFrame,
    required super.absoluteStartFrame,
    required super.depth,
  }) : assert(localStartFrame >= 0),
       assert(absoluteStartFrame >= 0);

  int get localFrame => localStartFrame;

  int get absoluteFrame => absoluteStartFrame;

  @override
  int get localEndFrame => localFrame;

  @override
  int get absoluteEndFrame => absoluteFrame;

  @override
  bool containsCue(String otherCueId) => cueId == otherCueId;
}
