import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";

part "scene.freezed.dart";
part "scene.g.dart";

@freezed
abstract class Cue with _$Cue {
  const factory Cue.segment({
    required String id,
    required int startFrame,
    required int endFrame,
    required DynamicData data,
    required List<ElementLink> inwardLinks,
    required List<ElementLink> outwardLinks,
  }) = Segment;

  const factory Cue.keyframe({
    required String id,
    required int frame,
    required DynamicData data,
    required List<ElementLink> inwardLinks,
  }) = Keyframe;

  factory Cue.fromJson(Map<String, dynamic> json) => _$CueFromJson(json);
}
