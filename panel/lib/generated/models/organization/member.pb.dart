// This is a generated file - do not edit.
//
// Generated from models/organization/member.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'role.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// OrganizationMember represents a user who is a member of an organization.
class OrganizationMember extends $pb.GeneratedMessage {
  factory OrganizationMember({
    $core.String? id,
    $core.String? name,
    $core.String? email,
    $core.String? avatarUrl,
    $core.Iterable<$0.Role>? roles,
    $1.Timestamp? joinedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (email != null) result.email = email;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (roles != null) result.roles.addAll(roles);
    if (joinedAt != null) result.joinedAt = joinedAt;
    return result;
  }

  OrganizationMember._();

  factory OrganizationMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrganizationMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrganizationMember',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..pPM<$0.Role>(5, _omitFieldNames ? '' : 'roles',
        subBuilder: $0.Role.create)
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'joinedAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationMember clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationMember copyWith(void Function(OrganizationMember) updates) =>
      super.copyWith((message) => updates(message as OrganizationMember))
          as OrganizationMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrganizationMember create() => OrganizationMember._();
  @$core.override
  OrganizationMember createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrganizationMember getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrganizationMember>(create);
  static OrganizationMember? _defaultInstance;

  /// Unique identifier for the member (the member_of relation ID)
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Display name of the member
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Email address of the member
  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  /// URL to the member's avatar image
  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  /// Roles assigned to this member
  @$pb.TagNumber(5)
  $pb.PbList<$0.Role> get roles => $_getList(4);

  /// Timestamp when the member joined the organization
  @$pb.TagNumber(6)
  $1.Timestamp get joinedAt => $_getN(5);
  @$pb.TagNumber(6)
  set joinedAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasJoinedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearJoinedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureJoinedAt() => $_ensure(5);
}

/// JoinRequest represents a pending request from a user to join an organization.
class JoinRequest extends $pb.GeneratedMessage {
  factory JoinRequest({
    $core.String? id,
    $core.String? userId,
    $core.String? userName,
    $core.String? userEmail,
    $core.String? userAvatarUrl,
    $1.Timestamp? requestedAt,
    $1.Timestamp? expiresAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (userName != null) result.userName = userName;
    if (userEmail != null) result.userEmail = userEmail;
    if (userAvatarUrl != null) result.userAvatarUrl = userAvatarUrl;
    if (requestedAt != null) result.requestedAt = requestedAt;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  JoinRequest._();

  factory JoinRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'userName')
    ..aOS(4, _omitFieldNames ? '' : 'userEmail')
    ..aOS(5, _omitFieldNames ? '' : 'userAvatarUrl')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'requestedAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(7, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinRequest copyWith(void Function(JoinRequest) updates) =>
      super.copyWith((message) => updates(message as JoinRequest))
          as JoinRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinRequest create() => JoinRequest._();
  @$core.override
  JoinRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JoinRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinRequest>(create);
  static JoinRequest? _defaultInstance;

  /// Unique identifier for the join request (the requests_to_join relation ID)
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Unique identifier of the requesting user
  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  /// Display name of the requesting user
  @$pb.TagNumber(3)
  $core.String get userName => $_getSZ(2);
  @$pb.TagNumber(3)
  set userName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserName() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserName() => $_clearField(3);

  /// Email address of the requesting user
  @$pb.TagNumber(4)
  $core.String get userEmail => $_getSZ(3);
  @$pb.TagNumber(4)
  set userEmail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserEmail() => $_clearField(4);

  /// URL to the requesting user's avatar image
  @$pb.TagNumber(5)
  $core.String get userAvatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set userAvatarUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUserAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserAvatarUrl() => $_clearField(5);

  /// Timestamp when the request was created
  @$pb.TagNumber(6)
  $1.Timestamp get requestedAt => $_getN(5);
  @$pb.TagNumber(6)
  set requestedAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRequestedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearRequestedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureRequestedAt() => $_ensure(5);

  /// Timestamp when the request expires
  @$pb.TagNumber(7)
  $1.Timestamp get expiresAt => $_getN(6);
  @$pb.TagNumber(7)
  set expiresAt($1.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasExpiresAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpiresAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureExpiresAt() => $_ensure(6);
}

/// UserJoinRequest represents a user's own pending request to join an organization.
/// This is from the user's perspective, showing which organizations they've requested to join.
class UserJoinRequest extends $pb.GeneratedMessage {
  factory UserJoinRequest({
    $core.String? id,
    $core.String? organizationId,
    $core.String? organizationName,
    $core.String? organizationIconUrl,
    $1.Timestamp? requestedAt,
    $1.Timestamp? expiresAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (organizationId != null) result.organizationId = organizationId;
    if (organizationName != null) result.organizationName = organizationName;
    if (organizationIconUrl != null)
      result.organizationIconUrl = organizationIconUrl;
    if (requestedAt != null) result.requestedAt = requestedAt;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  UserJoinRequest._();

  factory UserJoinRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserJoinRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserJoinRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'organizationId')
    ..aOS(3, _omitFieldNames ? '' : 'organizationName')
    ..aOS(4, _omitFieldNames ? '' : 'organizationIconUrl')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'requestedAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserJoinRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserJoinRequest copyWith(void Function(UserJoinRequest) updates) =>
      super.copyWith((message) => updates(message as UserJoinRequest))
          as UserJoinRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserJoinRequest create() => UserJoinRequest._();
  @$core.override
  UserJoinRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserJoinRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserJoinRequest>(create);
  static UserJoinRequest? _defaultInstance;

  /// Unique identifier for the join request (the requests_to_join relation ID)
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Organization ID the user is requesting to join
  @$pb.TagNumber(2)
  $core.String get organizationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set organizationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrganizationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrganizationId() => $_clearField(2);

  /// Organization name
  @$pb.TagNumber(3)
  $core.String get organizationName => $_getSZ(2);
  @$pb.TagNumber(3)
  set organizationName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOrganizationName() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrganizationName() => $_clearField(3);

  /// Organization icon URL
  @$pb.TagNumber(4)
  $core.String get organizationIconUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set organizationIconUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOrganizationIconUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrganizationIconUrl() => $_clearField(4);

  /// Timestamp when the request was created
  @$pb.TagNumber(5)
  $1.Timestamp get requestedAt => $_getN(4);
  @$pb.TagNumber(5)
  set requestedAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRequestedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureRequestedAt() => $_ensure(4);

  /// Timestamp when the request expires
  @$pb.TagNumber(6)
  $1.Timestamp get expiresAt => $_getN(5);
  @$pb.TagNumber(6)
  set expiresAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasExpiresAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpiresAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureExpiresAt() => $_ensure(5);
}

/// JoinCode represents a code that can be used to request to join an organization.
class JoinCode extends $pb.GeneratedMessage {
  factory JoinCode({
    $core.String? code,
    $1.Timestamp? createdAt,
    $1.Timestamp? expiresAt,
    $core.bool? singleUse,
    JoinCodeAutoAccept? autoAccept,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (createdAt != null) result.createdAt = createdAt;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (singleUse != null) result.singleUse = singleUse;
    if (autoAccept != null) result.autoAccept = autoAccept;
    return result;
  }

  JoinCode._();

  factory JoinCode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinCode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinCode',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.create)
    ..aOB(5, _omitFieldNames ? '' : 'singleUse')
    ..aOM<JoinCodeAutoAccept>(6, _omitFieldNames ? '' : 'autoAccept',
        subBuilder: JoinCodeAutoAccept.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinCode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinCode copyWith(void Function(JoinCode) updates) =>
      super.copyWith((message) => updates(message as JoinCode)) as JoinCode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinCode create() => JoinCode._();
  @$core.override
  JoinCode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JoinCode getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinCode>(create);
  static JoinCode? _defaultInstance;

  /// The code string (e.g., "abc123")
  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  /// Timestamp when the code was created
  @$pb.TagNumber(3)
  $1.Timestamp get createdAt => $_getN(1);
  @$pb.TagNumber(3)
  set createdAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(1);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureCreatedAt() => $_ensure(1);

  /// Timestamp when the code expires (not set = never expires)
  @$pb.TagNumber(4)
  $1.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(4)
  set expiresAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureExpiresAt() => $_ensure(2);

  /// Whether this code can only be used once (deleted after use)
  @$pb.TagNumber(5)
  $core.bool get singleUse => $_getBF(3);
  @$pb.TagNumber(5)
  set singleUse($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasSingleUse() => $_has(3);
  @$pb.TagNumber(5)
  void clearSingleUse() => $_clearField(5);

  /// Auto-accept configuration (not set = manual approval required)
  @$pb.TagNumber(6)
  JoinCodeAutoAccept get autoAccept => $_getN(4);
  @$pb.TagNumber(6)
  set autoAccept(JoinCodeAutoAccept value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAutoAccept() => $_has(4);
  @$pb.TagNumber(6)
  void clearAutoAccept() => $_clearField(6);
  @$pb.TagNumber(6)
  JoinCodeAutoAccept ensureAutoAccept() => $_ensure(4);
}

/// JoinCodeAutoAccept contains the configuration for auto-accepting users.
class JoinCodeAutoAccept extends $pb.GeneratedMessage {
  factory JoinCodeAutoAccept({
    $core.Iterable<$core.String>? roleIds,
  }) {
    final result = create();
    if (roleIds != null) result.roleIds.addAll(roleIds);
    return result;
  }

  JoinCodeAutoAccept._();

  factory JoinCodeAutoAccept.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinCodeAutoAccept.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinCodeAutoAccept',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'roleIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinCodeAutoAccept clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinCodeAutoAccept copyWith(void Function(JoinCodeAutoAccept) updates) =>
      super.copyWith((message) => updates(message as JoinCodeAutoAccept))
          as JoinCodeAutoAccept;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinCodeAutoAccept create() => JoinCodeAutoAccept._();
  @$core.override
  JoinCodeAutoAccept createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JoinCodeAutoAccept getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinCodeAutoAccept>(create);
  static JoinCodeAutoAccept? _defaultInstance;

  /// Role IDs to assign to auto-accepted users
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get roleIds => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
