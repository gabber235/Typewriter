// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_blueprint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ElementBlueprint _$ElementBlueprintFromJson(Map<String, dynamic> json) =>
    _ElementBlueprint(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      extension: json['extension'] as String,
      dataBlueprint: ObjectBlueprint.fromJson(
        json['dataBlueprint'] as Map<String, dynamic>,
      ),
      color: json['color'] == null
          ? Colors.grey
          : const ColorConverter().fromJson(json['color'] as String),
      icon: json['icon'] as String? ?? "fa-solid:question-circle",
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      genericConstraints:
          (json['genericConstraints'] as List<dynamic>?)
              ?.map((e) => DataBlueprint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          null,
      variableDataBlueprint: json['variableDataBlueprint'] == null
          ? null
          : DataBlueprint.fromJson(
              json['variableDataBlueprint'] as Map<String, dynamic>,
            ),
      contextKeys:
          (json['contextKeys'] as List<dynamic>?)
              ?.map((e) => ContextKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => ElementModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ElementBlueprintToJson(_ElementBlueprint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'extension': instance.extension,
      'dataBlueprint': instance.dataBlueprint.toJson(),
      'color': const ColorConverter().toJson(instance.color),
      'icon': instance.icon,
      'tags': instance.tags,
      'genericConstraints': instance.genericConstraints
          ?.map((e) => e.toJson())
          .toList(),
      'variableDataBlueprint': instance.variableDataBlueprint?.toJson(),
      'contextKeys': instance.contextKeys.map((e) => e.toJson()).toList(),
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
    };

_ContextKey _$ContextKeyFromJson(Map<String, dynamic> json) => _ContextKey(
  name: json['name'] as String,
  klassName: json['klassName'] as String,
  blueprint: DataBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContextKeyToJson(_ContextKey instance) =>
    <String, dynamic>{
      'name': instance.name,
      'klassName': instance.klassName,
      'blueprint': instance.blueprint.toJson(),
    };

_EmptyModifier _$EmptyModifierFromJson(Map<String, dynamic> json) =>
    _EmptyModifier($type: json['kind'] as String?);

Map<String, dynamic> _$EmptyModifierToJson(_EmptyModifier instance) =>
    <String, dynamic>{'kind': instance.$type};

DeprecatedModifier _$DeprecatedModifierFromJson(Map<String, dynamic> json) =>
    DeprecatedModifier(
      reason: json['reason'] as String? ?? "",
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$DeprecatedModifierToJson(DeprecatedModifier instance) =>
    <String, dynamic>{'reason': instance.reason, 'kind': instance.$type};
