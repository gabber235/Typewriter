// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_blueprint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DataBlueprintType _$DataBlueprintTypeFromJson(Map<String, dynamic> json) =>
    _DataBlueprintType(
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$DataBlueprintTypeToJson(_DataBlueprintType instance) =>
    <String, dynamic>{
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

PrimitiveBlueprint _$PrimitiveBlueprintFromJson(Map<String, dynamic> json) =>
    PrimitiveBlueprint(
      type: $enumDecode(_$PrimitiveTypeEnumMap, json['type']),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$PrimitiveBlueprintToJson(PrimitiveBlueprint instance) =>
    <String, dynamic>{
      'type': _$PrimitiveTypeEnumMap[instance.type]!,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

const _$PrimitiveTypeEnumMap = {
  PrimitiveType.boolean: 'boolean',
  PrimitiveType.double: 'double',
  PrimitiveType.integer: 'integer',
  PrimitiveType.string: 'string',
};

EnumBlueprint _$EnumBlueprintFromJson(Map<String, dynamic> json) =>
    EnumBlueprint(
      values:
          (json['values'] as List<dynamic>).map((e) => e as String).toList(),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$EnumBlueprintToJson(EnumBlueprint instance) =>
    <String, dynamic>{
      'values': instance.values,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

ListBlueprint _$ListBlueprintFromJson(Map<String, dynamic> json) =>
    ListBlueprint(
      type: DataBlueprint.fromJson(json['type'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ListBlueprintToJson(ListBlueprint instance) =>
    <String, dynamic>{
      'type': instance.type,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

MapBlueprint _$MapBlueprintFromJson(Map<String, dynamic> json) => MapBlueprint(
      key: DataBlueprint.fromJson(json['key'] as Map<String, dynamic>),
      value: DataBlueprint.fromJson(json['value'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$MapBlueprintToJson(MapBlueprint instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

ObjectBlueprint _$ObjectBlueprintFromJson(Map<String, dynamic> json) =>
    ObjectBlueprint(
      fields: (json['fields'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DataBlueprint.fromJson(e as Map<String, dynamic>)),
      ),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ObjectBlueprintToJson(ObjectBlueprint instance) =>
    <String, dynamic>{
      'fields': instance.fields,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

AlgebraicBlueprint _$AlgebraicBlueprintFromJson(Map<String, dynamic> json) =>
    AlgebraicBlueprint(
      cases: (json['cases'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DataBlueprint.fromJson(e as Map<String, dynamic>)),
      ),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$AlgebraicBlueprintToJson(AlgebraicBlueprint instance) =>
    <String, dynamic>{
      'cases': instance.cases,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

CustomBlueprint _$CustomBlueprintFromJson(Map<String, dynamic> json) =>
    CustomBlueprint(
      editor: json['editor'] as String,
      shape: DataBlueprint.fromJson(json['shape'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$CustomBlueprintToJson(CustomBlueprint instance) =>
    <String, dynamic>{
      'editor': instance.editor,
      'shape': instance.shape,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers,
      'kind': instance.$type,
    };

MultilineModifier _$MultilineModifierFromJson(Map<String, dynamic> json) =>
    MultilineModifier(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$MultilineModifierToJson(MultilineModifier instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

SnakeCaseModifier _$SnakeCaseModifierFromJson(Map<String, dynamic> json) =>
    SnakeCaseModifier(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$SnakeCaseModifierToJson(SnakeCaseModifier instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

GeneratedModifier _$GeneratedModifierFromJson(Map<String, dynamic> json) =>
    GeneratedModifier(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$GeneratedModifierToJson(GeneratedModifier instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

MinModifier _$MinModifierFromJson(Map<String, dynamic> json) => MinModifier(
      json['value'] as num,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$MinModifierToJson(MinModifier instance) =>
    <String, dynamic>{
      'value': instance.value,
      'kind': instance.$type,
    };

MaxModifier _$MaxModifierFromJson(Map<String, dynamic> json) => MaxModifier(
      json['value'] as num,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$MaxModifierToJson(MaxModifier instance) =>
    <String, dynamic>{
      'value': instance.value,
      'kind': instance.$type,
    };

NegativeModifier _$NegativeModifierFromJson(Map<String, dynamic> json) =>
    NegativeModifier(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$NegativeModifierToJson(NegativeModifier instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

CustomModifier _$CustomModifierFromJson(Map<String, dynamic> json) =>
    CustomModifier(
      name: json['name'] as String,
      data: json['data'],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$CustomModifierToJson(CustomModifier instance) =>
    <String, dynamic>{
      'name': instance.name,
      'data': instance.data,
      'kind': instance.$type,
    };
