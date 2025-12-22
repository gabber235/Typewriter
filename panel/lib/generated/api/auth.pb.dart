// This is a generated file - do not edit.
//
// Generated from api/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/auth.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PermissionRequest extends $pb.GeneratedMessage {
  factory PermissionRequest({
    $core.String? organizationId,
    $core.List<$core.int>? jwtClaims,
  }) {
    final result = create();
    if (organizationId != null) result.organizationId = organizationId;
    if (jwtClaims != null) result.jwtClaims = jwtClaims;
    return result;
  }

  PermissionRequest._();

  factory PermissionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PermissionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'organizationId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'jwtClaims', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionRequest copyWith(void Function(PermissionRequest) updates) =>
      super.copyWith((message) => updates(message as PermissionRequest))
          as PermissionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PermissionRequest create() => PermissionRequest._();
  @$core.override
  PermissionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PermissionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PermissionRequest>(create);
  static PermissionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get organizationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set organizationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganizationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganizationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get jwtClaims => $_getN(1);
  @$pb.TagNumber(2)
  set jwtClaims($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJwtClaims() => $_has(1);
  @$pb.TagNumber(2)
  void clearJwtClaims() => $_clearField(2);
}

class PermissionResponse extends $pb.GeneratedMessage {
  factory PermissionResponse({
    $0.Permissions? permissions,
    $core.Iterable<$core.String>? tags,
  }) {
    final result = create();
    if (permissions != null) result.permissions = permissions;
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  PermissionResponse._();

  factory PermissionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PermissionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOM<$0.Permissions>(1, _omitFieldNames ? '' : 'permissions',
        subBuilder: $0.Permissions.create)
    ..pPS(2, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionResponse copyWith(void Function(PermissionResponse) updates) =>
      super.copyWith((message) => updates(message as PermissionResponse))
          as PermissionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PermissionResponse create() => PermissionResponse._();
  @$core.override
  PermissionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PermissionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PermissionResponse>(create);
  static PermissionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Permissions get permissions => $_getN(0);
  @$pb.TagNumber(1)
  set permissions($0.Permissions value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPermissions() => $_has(0);
  @$pb.TagNumber(1)
  void clearPermissions() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Permissions ensurePermissions() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get tags => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
