// This is a generated file - do not edit.
//
// Generated from models/module.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'module.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'module.pbenum.dart';

class Module extends $pb.GeneratedMessage {
  factory Module({
    $core.String? id,
    $core.String? name,
    ModuleType? type,
    $core.String? shortDescription,
    $core.Iterable<ModuleVersion>? versions,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (shortDescription != null) result.shortDescription = shortDescription;
    if (versions != null) result.versions.addAll(versions);
    return result;
  }

  Module._();

  factory Module.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Module.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Module',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<ModuleType>(3, _omitFieldNames ? '' : 'type',
        enumValues: ModuleType.values)
    ..aOS(4, _omitFieldNames ? '' : 'shortDescription')
    ..pPM<ModuleVersion>(5, _omitFieldNames ? '' : 'versions',
        subBuilder: ModuleVersion.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Module clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Module copyWith(void Function(Module) updates) =>
      super.copyWith((message) => updates(message as Module)) as Module;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Module create() => Module._();
  @$core.override
  Module createEmptyInstance() => create();
  static $pb.PbList<Module> createRepeated() => $pb.PbList<Module>();
  @$core.pragma('dart2js:noInline')
  static Module getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Module>(create);
  static Module? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  ModuleType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(ModuleType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get shortDescription => $_getSZ(3);
  @$pb.TagNumber(4)
  set shortDescription($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShortDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearShortDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<ModuleVersion> get versions => $_getList(4);
}

class ModuleVersion extends $pb.GeneratedMessage {
  factory ModuleVersion({
    $core.String? version,
    ModuleVersionState? state,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (state != null) result.state = state;
    return result;
  }

  ModuleVersion._();

  factory ModuleVersion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleVersion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleVersion',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aE<ModuleVersionState>(2, _omitFieldNames ? '' : 'state',
        enumValues: ModuleVersionState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleVersion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleVersion copyWith(void Function(ModuleVersion) updates) =>
      super.copyWith((message) => updates(message as ModuleVersion))
          as ModuleVersion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleVersion create() => ModuleVersion._();
  @$core.override
  ModuleVersion createEmptyInstance() => create();
  static $pb.PbList<ModuleVersion> createRepeated() =>
      $pb.PbList<ModuleVersion>();
  @$core.pragma('dart2js:noInline')
  static ModuleVersion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleVersion>(create);
  static ModuleVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  ModuleVersionState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(ModuleVersionState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
