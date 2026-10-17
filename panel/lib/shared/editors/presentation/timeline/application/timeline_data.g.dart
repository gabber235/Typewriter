// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TimelineTrackToJson(TimelineTrack instance) =>
    <String, dynamic>{
      'id': const TimelineIdentifierJsonConverter().toJson(instance.id),
      'elements': instance.elements.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$TimelineSegmentToJson(TimelineSegment instance) =>
    <String, dynamic>{
      'id': const TimelineIdentifierJsonConverter().toJson(instance.id),
      'color': const ColorConverter().toJson(instance.color),
      'parentId': _$JsonConverterToJson<String, TimelineIdentifier>(
        instance.parentId,
        const TimelineIdentifierJsonConverter().toJson,
      ),
      'frameDuration': instance.frameDuration,
      'startFrame': instance.startFrame,
      'endFrame': instance.endFrame,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'hasChildren': instance.hasChildren,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

Map<String, dynamic> _$TimelineKeyframeToJson(TimelineKeyframe instance) =>
    <String, dynamic>{
      'id': const TimelineIdentifierJsonConverter().toJson(instance.id),
      'color': const ColorConverter().toJson(instance.color),
      'parentId': _$JsonConverterToJson<String, TimelineIdentifier>(
        instance.parentId,
        const TimelineIdentifierJsonConverter().toJson,
      ),
      'frameDuration': instance.frameDuration,
      'frame': instance.frame,
      'hasChildren': instance.hasChildren,
    };

Map<String, dynamic> _$TimelineTrackBlockToJson(
  TimelineTrackBlock instance,
) => <String, dynamic>{
  'trackId': const TimelineIdentifierJsonConverter().toJson(instance.trackId),
  'element': instance.element.toJson(),
  'previewState': _$TimelinePreviewStateEnumMap[instance.previewState]!,
  'height': instance.height,
  'children': instance.children.map((e) => e.toJson()).toList(),
};

const _$TimelinePreviewStateEnumMap = {
  TimelinePreviewState.none: 'none',
  TimelinePreviewState.active: 'active',
  TimelinePreviewState.related: 'related',
};

Map<String, dynamic> _$TimelineTrackBlockPlacementToJson(
  TimelineTrackBlockPlacement instance,
) => <String, dynamic>{'block': instance.block.toJson(), 'lane': instance.lane};

Map<String, dynamic> _$TimelinePlacedElementToJson(
  TimelinePlacedElement instance,
) => <String, dynamic>{
  'trackId': const TimelineIdentifierJsonConverter().toJson(instance.trackId),
  'element': instance.element.toJson(),
  'laneIndex': instance.laneIndex,
  'rect': const RectConverter().toJson(instance.rect),
  'childrenRect': _$JsonConverterToJson<Map<String, dynamic>, Rect>(
    instance.childrenRect,
    const RectConverter().toJson,
  ),
  'previewState': _$TimelinePreviewStateEnumMap[instance.previewState]!,
};
