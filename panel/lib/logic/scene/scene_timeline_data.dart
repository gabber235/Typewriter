import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_track.dart";

class SceneTimelineData {
  const SceneTimelineData({required this.tracks});

  final List<SceneTimelineTrack> tracks;

  SceneTimelineTrack? trackByCueId(String cueId) {
    for (final track in tracks) {
      if (track.itemByCueId(cueId) != null) return track;
    }
    return null;
  }

  SceneTimelineItem? itemByCueId(String cueId) {
    for (final track in tracks) {
      final item = track.itemByCueId(cueId);
      if (item != null) return item;
    }
    return null;
  }
}
