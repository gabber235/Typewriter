// This is a generated file - do not edit.
//
// Generated from api/service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/common.pb.dart' as $1;
import '../models/service.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// IssueServiceIdentityRequest requests the issuance of a new service identity.
class IssueServiceIdentityRequest extends $pb.GeneratedMessage {
  factory IssueServiceIdentityRequest({
    $core.Iterable<$0.ServiceType>? serviceTypes,
    $0.ServiceMetadata? metadata,
  }) {
    final result = create();
    if (serviceTypes != null) result.serviceTypes.addAll(serviceTypes);
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  IssueServiceIdentityRequest._();

  factory IssueServiceIdentityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IssueServiceIdentityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueServiceIdentityRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pc<$0.ServiceType>(
        2, _omitFieldNames ? '' : 'serviceTypes', $pb.PbFieldType.KE,
        valueOf: $0.ServiceType.valueOf,
        enumValues: $0.ServiceType.values,
        defaultEnumValue: $0.ServiceType.SERVICE_TYPE_UNSPECIFIED)
    ..aOM<$0.ServiceMetadata>(3, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.ServiceMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueServiceIdentityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueServiceIdentityRequest copyWith(
          void Function(IssueServiceIdentityRequest) updates) =>
      super.copyWith(
              (message) => updates(message as IssueServiceIdentityRequest))
          as IssueServiceIdentityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IssueServiceIdentityRequest create() =>
      IssueServiceIdentityRequest._();
  @$core.override
  IssueServiceIdentityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IssueServiceIdentityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IssueServiceIdentityRequest>(create);
  static IssueServiceIdentityRequest? _defaultInstance;

  /// List of service types (engine and/or realm).
  @$pb.TagNumber(2)
  $pb.PbList<$0.ServiceType> get serviceTypes => $_getList(0);

  /// Metadata about the service.
  @$pb.TagNumber(3)
  $0.ServiceMetadata get metadata => $_getN(1);
  @$pb.TagNumber(3)
  set metadata($0.ServiceMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(1);
  @$pb.TagNumber(3)
  void clearMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.ServiceMetadata ensureMetadata() => $_ensure(1);
}

enum IssueServiceIdentityResponse_Result { credentials, error, notSet }

/// IssueServiceIdentityResponse returns the credentials or an error.
class IssueServiceIdentityResponse extends $pb.GeneratedMessage {
  factory IssueServiceIdentityResponse({
    ServiceCredentials? credentials,
    $1.Error? error,
  }) {
    final result = create();
    if (credentials != null) result.credentials = credentials;
    if (error != null) result.error = error;
    return result;
  }

  IssueServiceIdentityResponse._();

  factory IssueServiceIdentityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IssueServiceIdentityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, IssueServiceIdentityResponse_Result>
      _IssueServiceIdentityResponse_ResultByTag = {
    1: IssueServiceIdentityResponse_Result.credentials,
    2: IssueServiceIdentityResponse_Result.error,
    0: IssueServiceIdentityResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueServiceIdentityResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ServiceCredentials>(1, _omitFieldNames ? '' : 'credentials',
        subBuilder: ServiceCredentials.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueServiceIdentityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueServiceIdentityResponse copyWith(
          void Function(IssueServiceIdentityResponse) updates) =>
      super.copyWith(
              (message) => updates(message as IssueServiceIdentityResponse))
          as IssueServiceIdentityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IssueServiceIdentityResponse create() =>
      IssueServiceIdentityResponse._();
  @$core.override
  IssueServiceIdentityResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IssueServiceIdentityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IssueServiceIdentityResponse>(create);
  static IssueServiceIdentityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  IssueServiceIdentityResponse_Result whichResult() =>
      _IssueServiceIdentityResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ServiceCredentials get credentials => $_getN(0);
  @$pb.TagNumber(1)
  set credentials(ServiceCredentials value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCredentials() => $_has(0);
  @$pb.TagNumber(1)
  void clearCredentials() => $_clearField(1);
  @$pb.TagNumber(1)
  ServiceCredentials ensureCredentials() => $_ensure(0);

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

/// ServiceCredentials contains the authentication credentials for a service.
/// IMPORTANT: The token is only shown once and cannot be retrieved again.
class ServiceCredentials extends $pb.GeneratedMessage {
  factory ServiceCredentials({
    $core.String? serviceId,
    $core.String? username,
    $core.String? token,
  }) {
    final result = create();
    if (serviceId != null) result.serviceId = serviceId;
    if (username != null) result.username = username;
    if (token != null) result.token = token;
    return result;
  }

  ServiceCredentials._();

  factory ServiceCredentials.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceCredentials.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceCredentials',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceCredentials clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceCredentials copyWith(void Function(ServiceCredentials) updates) =>
      super.copyWith((message) => updates(message as ServiceCredentials))
          as ServiceCredentials;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceCredentials create() => ServiceCredentials._();
  @$core.override
  ServiceCredentials createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceCredentials getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceCredentials>(create);
  static ServiceCredentials? _defaultInstance;

  /// Service identifier (SurrealDB record ID, which is the Authentik user ID).
  @$pb.TagNumber(1)
  $core.String get serviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceId() => $_clearField(1);

  /// Authentik username for the service.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// Authentik authentication token (shown once only!).
  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
