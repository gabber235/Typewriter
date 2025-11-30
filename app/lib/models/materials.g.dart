// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MinecraftMaterialImpl _$$MinecraftMaterialImplFromJson(
        Map<String, dynamic> json) =>
    _$MinecraftMaterialImpl(
      name: json['name'] as String,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => $enumDecode(_$MaterialPropertyEnumMap, e))
          .toList(),
      icon: json['icon'] as String,
      since: $enumDecodeNullable(_$McVersionEnumMap, json['since']),
    );

Map<String, dynamic> _$$MinecraftMaterialImplToJson(
        _$MinecraftMaterialImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'properties': instance.properties
          .map((e) => _$MaterialPropertyEnumMap[e]!)
          .toList(),
      'icon': instance.icon,
      'since': _$McVersionEnumMap[instance.since],
    };

const _$MaterialPropertyEnumMap = {
  MaterialProperty.item: 'item',
  MaterialProperty.block: 'block',
  MaterialProperty.solid: 'solid',
  MaterialProperty.transparent: 'transparent',
  MaterialProperty.intractable: 'intractable',
  MaterialProperty.occluding: 'occluding',
  MaterialProperty.record: 'record',
  MaterialProperty.tool: 'tool',
  MaterialProperty.weapon: 'weapon',
  MaterialProperty.armor: 'armor',
  MaterialProperty.flammable: 'flammable',
  MaterialProperty.burnable: 'burnable',
  MaterialProperty.edible: 'edible',
  MaterialProperty.fuel: 'fuel',
  MaterialProperty.ore: 'ore',
};

const _$McVersionEnumMap = {
  McVersion.zero: 'zero',
  McVersion.v1_8: 'v1_8',
  McVersion.v1_9: 'v1_9',
  McVersion.v1_10: 'v1_10',
  McVersion.v1_11: 'v1_11',
  McVersion.v1_12: 'v1_12',
  McVersion.v1_13: 'v1_13',
  McVersion.v1_14: 'v1_14',
  McVersion.v1_15: 'v1_15',
  McVersion.v1_16: 'v1_16',
  McVersion.v1_17: 'v1_17',
  McVersion.v1_18: 'v1_18',
  McVersion.v1_19: 'v1_19',
  McVersion.v1_20: 'v1_20',
  McVersion.v1_21: 'v1_21',
};
