// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Segment _$SegmentFromJson(Map<String, dynamic> json) => Segment(
  id: json['id'] as String,
  startFrame: (json['startFrame'] as num).toInt(),
  endFrame: (json['endFrame'] as num).toInt(),
  blueprint: ElementBlueprint.fromJson(
    json['blueprint'] as Map<String, dynamic>,
  ),
  data: DynamicData.fromJson(json['data'] as Map<String, dynamic>),
  inwardLinks: (json['inwardLinks'] as List<dynamic>)
      .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  outwardLinks: (json['outwardLinks'] as List<dynamic>)
      .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SegmentToJson(Segment instance) => <String, dynamic>{
  'id': instance.id,
  'startFrame': instance.startFrame,
  'endFrame': instance.endFrame,
  'blueprint': instance.blueprint.toJson(),
  'data': instance.data.toJson(),
  'inwardLinks': instance.inwardLinks.map((e) => e.toJson()).toList(),
  'outwardLinks': instance.outwardLinks.map((e) => e.toJson()).toList(),
  'runtimeType': instance.$type,
};

Keyframe _$KeyframeFromJson(Map<String, dynamic> json) => Keyframe(
  id: json['id'] as String,
  frame: (json['frame'] as num).toInt(),
  blueprint: ElementBlueprint.fromJson(
    json['blueprint'] as Map<String, dynamic>,
  ),
  data: DynamicData.fromJson(json['data'] as Map<String, dynamic>),
  inwardLinks: (json['inwardLinks'] as List<dynamic>)
      .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$KeyframeToJson(Keyframe instance) => <String, dynamic>{
  'id': instance.id,
  'frame': instance.frame,
  'blueprint': instance.blueprint.toJson(),
  'data': instance.data.toJson(),
  'inwardLinks': instance.inwardLinks.map((e) => e.toJson()).toList(),
  'runtimeType': instance.$type,
};
