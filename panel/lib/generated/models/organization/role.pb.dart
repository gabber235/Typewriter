// This is a generated file - do not edit.
//
// Generated from models/organization/role.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Role represents a role that can be assigned to organization members.
/// Roles define permissions and access levels within the organization.
class Role extends $pb.GeneratedMessage {
  factory Role({
    $core.String? id,
    $core.String? name,
    $0.Color? color,
    $core.bool? defaultRole,
    $core.bool? assignable,
    $core.bool? deletable,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (color != null) result.color = color;
    if (defaultRole != null) result.defaultRole = defaultRole;
    if (assignable != null) result.assignable = assignable;
    if (deletable != null) result.deletable = deletable;
    return result;
  }

  Role._();

  factory Role.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Role.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Role',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Color>(3, _omitFieldNames ? '' : 'color',
        subBuilder: $0.Color.create)
    ..aOB(4, _omitFieldNames ? '' : 'defaultRole')
    ..aOB(5, _omitFieldNames ? '' : 'assignable')
    ..aOB(6, _omitFieldNames ? '' : 'deletable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role copyWith(void Function(Role) updates) =>
      super.copyWith((message) => updates(message as Role)) as Role;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Role create() => Role._();
  @$core.override
  Role createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Role getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Role>(create);
  static Role? _defaultInstance;

  /// Unique identifier for the role
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Display name of the role (e.g., "Admin", "Editor", "Viewer")
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Color for the role in ARGB format
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

  /// Whether this is the default role assigned to new members
  @$pb.TagNumber(4)
  $core.bool get defaultRole => $_getBF(3);
  @$pb.TagNumber(4)
  set defaultRole($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefaultRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultRole() => $_clearField(4);

  /// Whether this role can be assigned by administrators
  @$pb.TagNumber(5)
  $core.bool get assignable => $_getBF(4);
  @$pb.TagNumber(5)
  set assignable($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAssignable() => $_has(4);
  @$pb.TagNumber(5)
  void clearAssignable() => $_clearField(5);

  /// Whether this role can be deleted by administrators
  @$pb.TagNumber(6)
  $core.bool get deletable => $_getBF(5);
  @$pb.TagNumber(6)
  set deletable($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDeletable() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeletable() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
