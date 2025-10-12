// This is a generated file - do not edit.
//
// Generated from models/manual.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;
import 'manual.pbenum.dart';
import 'module.pbenum.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'manual.pbenum.dart';

class Manual extends $pb.GeneratedMessage {
  factory Manual({
    $core.String? id,
    $core.String? name,
    $core.Iterable<PlatformTarget>? platforms,
    $core.Iterable<ManualModuleReference>? modules,
    $core.bool? autoUpdate,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (platforms != null) result.platforms.addAll(platforms);
    if (modules != null) result.modules.addAll(modules);
    if (autoUpdate != null) result.autoUpdate = autoUpdate;
    return result;
  }

  Manual._();

  factory Manual.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Manual.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Manual',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPM<PlatformTarget>(3, _omitFieldNames ? '' : 'platforms',
        subBuilder: PlatformTarget.create)
    ..pPM<ManualModuleReference>(4, _omitFieldNames ? '' : 'modules',
        subBuilder: ManualModuleReference.create)
    ..aOB(5, _omitFieldNames ? '' : 'autoUpdate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Manual clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Manual copyWith(void Function(Manual) updates) =>
      super.copyWith((message) => updates(message as Manual)) as Manual;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Manual create() => Manual._();
  @$core.override
  Manual createEmptyInstance() => create();
  static $pb.PbList<Manual> createRepeated() => $pb.PbList<Manual>();
  @$core.pragma('dart2js:noInline')
  static Manual getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Manual>(create);
  static Manual? _defaultInstance;

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
  $pb.PbList<PlatformTarget> get platforms => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<ManualModuleReference> get modules => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get autoUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set autoUpdate($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAutoUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoUpdate() => $_clearField(5);
}

class Platform extends $pb.GeneratedMessage {
  factory Platform({
    $core.String? id,
    $core.String? displayName,
    $0.Color? color,
    $core.Iterable<PlatformRequirement>? requirements,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (displayName != null) result.displayName = displayName;
    if (color != null) result.color = color;
    if (requirements != null) result.requirements.addAll(requirements);
    return result;
  }

  Platform._();

  factory Platform.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Platform.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Platform',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOM<$0.Color>(3, _omitFieldNames ? '' : 'color',
        subBuilder: $0.Color.create)
    ..pPM<PlatformRequirement>(4, _omitFieldNames ? '' : 'requirements',
        subBuilder: PlatformRequirement.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Platform clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Platform copyWith(void Function(Platform) updates) =>
      super.copyWith((message) => updates(message as Platform)) as Platform;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Platform create() => Platform._();
  @$core.override
  Platform createEmptyInstance() => create();
  static $pb.PbList<Platform> createRepeated() => $pb.PbList<Platform>();
  @$core.pragma('dart2js:noInline')
  static Platform getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Platform>(create);
  static Platform? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Color get color => $_getN(2);
  @$pb.TagNumber(3)
  set color($0.Color value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Color ensureColor() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<PlatformRequirement> get requirements => $_getList(3);
}

class PlatformRequirement extends $pb.GeneratedMessage {
  factory PlatformRequirement({
    $core.String? name,
    PlatformConstraintType? type,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    return result;
  }

  PlatformRequirement._();

  factory PlatformRequirement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlatformRequirement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlatformRequirement',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<PlatformConstraintType>(2, _omitFieldNames ? '' : 'type',
        enumValues: PlatformConstraintType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformRequirement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformRequirement copyWith(void Function(PlatformRequirement) updates) =>
      super.copyWith((message) => updates(message as PlatformRequirement))
          as PlatformRequirement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlatformRequirement create() => PlatformRequirement._();
  @$core.override
  PlatformRequirement createEmptyInstance() => create();
  static $pb.PbList<PlatformRequirement> createRepeated() =>
      $pb.PbList<PlatformRequirement>();
  @$core.pragma('dart2js:noInline')
  static PlatformRequirement getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlatformRequirement>(create);
  static PlatformRequirement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  PlatformConstraintType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(PlatformConstraintType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);
}

enum PlatformConstraint_Constraint { version, notSet }

class PlatformConstraint extends $pb.GeneratedMessage {
  factory PlatformConstraint({
    VersionConstraint? version,
  }) {
    final result = create();
    if (version != null) result.version = version;
    return result;
  }

  PlatformConstraint._();

  factory PlatformConstraint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlatformConstraint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PlatformConstraint_Constraint>
      _PlatformConstraint_ConstraintByTag = {
    1: PlatformConstraint_Constraint.version,
    0: PlatformConstraint_Constraint.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlatformConstraint',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<VersionConstraint>(1, _omitFieldNames ? '' : 'version',
        subBuilder: VersionConstraint.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformConstraint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformConstraint copyWith(void Function(PlatformConstraint) updates) =>
      super.copyWith((message) => updates(message as PlatformConstraint))
          as PlatformConstraint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlatformConstraint create() => PlatformConstraint._();
  @$core.override
  PlatformConstraint createEmptyInstance() => create();
  static $pb.PbList<PlatformConstraint> createRepeated() =>
      $pb.PbList<PlatformConstraint>();
  @$core.pragma('dart2js:noInline')
  static PlatformConstraint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlatformConstraint>(create);
  static PlatformConstraint? _defaultInstance;

  @$pb.TagNumber(1)
  PlatformConstraint_Constraint whichConstraint() =>
      _PlatformConstraint_ConstraintByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  void clearConstraint() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  VersionConstraint get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(VersionConstraint value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  VersionConstraint ensureVersion() => $_ensure(0);
}

class VersionConstraint extends $pb.GeneratedMessage {
  factory VersionConstraint({
    $core.Iterable<$0.Version>? versions,
  }) {
    final result = create();
    if (versions != null) result.versions.addAll(versions);
    return result;
  }

  VersionConstraint._();

  factory VersionConstraint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VersionConstraint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionConstraint',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Version>(1, _omitFieldNames ? '' : 'versions',
        subBuilder: $0.Version.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionConstraint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionConstraint copyWith(void Function(VersionConstraint) updates) =>
      super.copyWith((message) => updates(message as VersionConstraint))
          as VersionConstraint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionConstraint create() => VersionConstraint._();
  @$core.override
  VersionConstraint createEmptyInstance() => create();
  static $pb.PbList<VersionConstraint> createRepeated() =>
      $pb.PbList<VersionConstraint>();
  @$core.pragma('dart2js:noInline')
  static VersionConstraint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VersionConstraint>(create);
  static VersionConstraint? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Version> get versions => $_getList(0);
}

class PlatformTarget extends $pb.GeneratedMessage {
  factory PlatformTarget({
    Platform? platform,
    $core.Iterable<$core.MapEntry<$core.String, PlatformConstraint>>?
        constraints,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (constraints != null) result.constraints.addEntries(constraints);
    return result;
  }

  PlatformTarget._();

  factory PlatformTarget.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlatformTarget.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlatformTarget',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOM<Platform>(1, _omitFieldNames ? '' : 'platform',
        subBuilder: Platform.create)
    ..m<$core.String, PlatformConstraint>(
        2, _omitFieldNames ? '' : 'constraints',
        entryClassName: 'PlatformTarget.ConstraintsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: PlatformConstraint.create,
        valueDefaultOrMaker: PlatformConstraint.getDefault,
        packageName: const $pb.PackageName('typewriter.models.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformTarget clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformTarget copyWith(void Function(PlatformTarget) updates) =>
      super.copyWith((message) => updates(message as PlatformTarget))
          as PlatformTarget;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlatformTarget create() => PlatformTarget._();
  @$core.override
  PlatformTarget createEmptyInstance() => create();
  static $pb.PbList<PlatformTarget> createRepeated() =>
      $pb.PbList<PlatformTarget>();
  @$core.pragma('dart2js:noInline')
  static PlatformTarget getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlatformTarget>(create);
  static PlatformTarget? _defaultInstance;

  @$pb.TagNumber(1)
  Platform get platform => $_getN(0);
  @$pb.TagNumber(1)
  set platform(Platform value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);
  @$pb.TagNumber(1)
  Platform ensurePlatform() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, PlatformConstraint> get constraints => $_getMap(1);
}

class ManualModuleReference extends $pb.GeneratedMessage {
  factory ManualModuleReference({
    $core.String? moduleId,
    $core.String? name,
    $0.Version? version,
    $1.ModuleType? type,
    $core.Iterable<$core.String>? dependencies,
    $core.Iterable<$core.String>? dependents,
  }) {
    final result = create();
    if (moduleId != null) result.moduleId = moduleId;
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (type != null) result.type = type;
    if (dependencies != null) result.dependencies.addAll(dependencies);
    if (dependents != null) result.dependents.addAll(dependents);
    return result;
  }

  ManualModuleReference._();

  factory ManualModuleReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManualModuleReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManualModuleReference',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'moduleId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Version>(3, _omitFieldNames ? '' : 'version',
        subBuilder: $0.Version.create)
    ..aE<$1.ModuleType>(4, _omitFieldNames ? '' : 'type',
        enumValues: $1.ModuleType.values)
    ..pPS(5, _omitFieldNames ? '' : 'dependencies')
    ..pPS(6, _omitFieldNames ? '' : 'dependents')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualModuleReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualModuleReference copyWith(
          void Function(ManualModuleReference) updates) =>
      super.copyWith((message) => updates(message as ManualModuleReference))
          as ManualModuleReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManualModuleReference create() => ManualModuleReference._();
  @$core.override
  ManualModuleReference createEmptyInstance() => create();
  static $pb.PbList<ManualModuleReference> createRepeated() =>
      $pb.PbList<ManualModuleReference>();
  @$core.pragma('dart2js:noInline')
  static ManualModuleReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManualModuleReference>(create);
  static ManualModuleReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get moduleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set moduleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModuleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModuleId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Version get version => $_getN(2);
  @$pb.TagNumber(3)
  set version($0.Version value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Version ensureVersion() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.ModuleType get type => $_getN(3);
  @$pb.TagNumber(4)
  set type($1.ModuleType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get dependencies => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get dependents => $_getList(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
