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
import '../models/common.pb.dart' as $1;

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

/// GetSentinelCredentialsRequest requests the NATS sentinel credentials.
/// This endpoint is unauthenticated as sentinel credentials are needed
/// before authentication can occur.
class GetSentinelCredentialsRequest extends $pb.GeneratedMessage {
  factory GetSentinelCredentialsRequest() => create();

  GetSentinelCredentialsRequest._();

  factory GetSentinelCredentialsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSentinelCredentialsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSentinelCredentialsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSentinelCredentialsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSentinelCredentialsRequest copyWith(
          void Function(GetSentinelCredentialsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetSentinelCredentialsRequest))
          as GetSentinelCredentialsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSentinelCredentialsRequest create() =>
      GetSentinelCredentialsRequest._();
  @$core.override
  GetSentinelCredentialsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSentinelCredentialsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSentinelCredentialsRequest>(create);
  static GetSentinelCredentialsRequest? _defaultInstance;
}

enum GetSentinelCredentialsResponse_Result { credentials, error, notSet }

/// GetSentinelCredentialsResponse returns the sentinel credentials or an error.
class GetSentinelCredentialsResponse extends $pb.GeneratedMessage {
  factory GetSentinelCredentialsResponse({
    SentinelCredentials? credentials,
    $1.Error? error,
  }) {
    final result = create();
    if (credentials != null) result.credentials = credentials;
    if (error != null) result.error = error;
    return result;
  }

  GetSentinelCredentialsResponse._();

  factory GetSentinelCredentialsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSentinelCredentialsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetSentinelCredentialsResponse_Result>
      _GetSentinelCredentialsResponse_ResultByTag = {
    1: GetSentinelCredentialsResponse_Result.credentials,
    2: GetSentinelCredentialsResponse_Result.error,
    0: GetSentinelCredentialsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSentinelCredentialsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SentinelCredentials>(1, _omitFieldNames ? '' : 'credentials',
        subBuilder: SentinelCredentials.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSentinelCredentialsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSentinelCredentialsResponse copyWith(
          void Function(GetSentinelCredentialsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetSentinelCredentialsResponse))
          as GetSentinelCredentialsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSentinelCredentialsResponse create() =>
      GetSentinelCredentialsResponse._();
  @$core.override
  GetSentinelCredentialsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSentinelCredentialsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSentinelCredentialsResponse>(create);
  static GetSentinelCredentialsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetSentinelCredentialsResponse_Result whichResult() =>
      _GetSentinelCredentialsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SentinelCredentials get credentials => $_getN(0);
  @$pb.TagNumber(1)
  set credentials(SentinelCredentials value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCredentials() => $_has(0);
  @$pb.TagNumber(1)
  void clearCredentials() => $_clearField(1);
  @$pb.TagNumber(1)
  SentinelCredentials ensureCredentials() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Error ensureError() => $_ensure(1);
}

/// SentinelCredentials contains the NATS sentinel JWT and seed.
/// These credentials have no permissions and are only used to identify
/// the account during NATS auth callout.
class SentinelCredentials extends $pb.GeneratedMessage {
  factory SentinelCredentials({
    $core.String? jwt,
    $core.String? seed,
  }) {
    final result = create();
    if (jwt != null) result.jwt = jwt;
    if (seed != null) result.seed = seed;
    return result;
  }

  SentinelCredentials._();

  factory SentinelCredentials.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SentinelCredentials.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SentinelCredentials',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jwt')
    ..aOS(2, _omitFieldNames ? '' : 'seed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SentinelCredentials clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SentinelCredentials copyWith(void Function(SentinelCredentials) updates) =>
      super.copyWith((message) => updates(message as SentinelCredentials))
          as SentinelCredentials;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SentinelCredentials create() => SentinelCredentials._();
  @$core.override
  SentinelCredentials createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SentinelCredentials getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SentinelCredentials>(create);
  static SentinelCredentials? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jwt => $_getSZ(0);
  @$pb.TagNumber(1)
  set jwt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJwt() => $_has(0);
  @$pb.TagNumber(1)
  void clearJwt() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get seed => $_getSZ(1);
  @$pb.TagNumber(2)
  set seed($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeed() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeed() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
