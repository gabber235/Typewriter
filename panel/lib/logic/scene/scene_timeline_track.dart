import "package:typewriter_panel/logic/scene/scene_identifier.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";

class SceneTimelineTrack {
  const SceneTimelineTrack({
    required this.id,
    required this.entryId,
    required this.rootItems,
  });

  final SceneIdentifier id;
  final String entryId;
  final List<SceneTimelineItem> rootItems;

  SceneTimelineItem? itemByCueId(String cueId) {
    for (final item in rootItems) {
      final found = _findItem(item, cueId);
      if (found != null) return found;
    }
    return null;
  }

  SceneSegmentItem? segmentByCueId(String cueId) {
    final item = itemByCueId(cueId);
    return item is SceneSegmentItem ? item : null;
  }

  SceneTimelineItem? _findItem(SceneTimelineItem item, String cueId) {
    if (item.cueId == cueId) return item;
    if (item is! SceneSegmentItem) return null;

    for (final child in item.children) {
      final found = _findItem(child, cueId);
      if (found != null) return found;
    }

    return null;
  }
}
