// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModuleVersion _$ModuleVersionFromJson(Map<String, dynamic> json) =>
    _ModuleVersion(
      version: const _SemverFlexibleConverter().fromJson(json['version']),
      state: $enumDecodeNullable(_$ModuleVersionStateEnumMap, json['state']) ??
          ModuleVersionState.developing,
    );

Map<String, dynamic> _$ModuleVersionToJson(_ModuleVersion instance) =>
    <String, dynamic>{
      'version': const _SemverFlexibleConverter().toJson(instance.version),
      'state': _$ModuleVersionStateEnumMap[instance.state]!,
    };

const _$ModuleVersionStateEnumMap = {
  ModuleVersionState.developing: 'developing',
  ModuleVersionState.published: 'published',
  ModuleVersionState.yoinked: 'yoinked',
};
