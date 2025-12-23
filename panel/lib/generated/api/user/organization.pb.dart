// This is a generated file - do not edit.
//
// Generated from api/user/organization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../models/common.pb.dart' as $0;
import '../../models/organization.pb.dart' as $1;
import '../../models/organization/member.pb.dart' as $2;
import '../../models/organization/role.pb.dart' as $3;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListOrganizationsRequest extends $pb.GeneratedMessage {
  factory ListOrganizationsRequest() => create();

  ListOrganizationsRequest._();

  factory ListOrganizationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListOrganizationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListOrganizationsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationsRequest copyWith(
          void Function(ListOrganizationsRequest) updates) =>
      super.copyWith((message) => updates(message as ListOrganizationsRequest))
          as ListOrganizationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListOrganizationsRequest create() => ListOrganizationsRequest._();
  @$core.override
  ListOrganizationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListOrganizationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListOrganizationsRequest>(create);
  static ListOrganizationsRequest? _defaultInstance;
}

enum ListOrganizationsResponse_Result { organizations, error, notSet }

class ListOrganizationsResponse extends $pb.GeneratedMessage {
  factory ListOrganizationsResponse({
    ListOrganizations? organizations,
    $0.Error? error,
  }) {
    final result = create();
    if (organizations != null) result.organizations = organizations;
    if (error != null) result.error = error;
    return result;
  }

  ListOrganizationsResponse._();

  factory ListOrganizationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListOrganizationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListOrganizationsResponse_Result>
      _ListOrganizationsResponse_ResultByTag = {
    1: ListOrganizationsResponse_Result.organizations,
    2: ListOrganizationsResponse_Result.error,
    0: ListOrganizationsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListOrganizationsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListOrganizations>(1, _omitFieldNames ? '' : 'organizations',
        subBuilder: ListOrganizations.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationsResponse copyWith(
          void Function(ListOrganizationsResponse) updates) =>
      super.copyWith((message) => updates(message as ListOrganizationsResponse))
          as ListOrganizationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListOrganizationsResponse create() => ListOrganizationsResponse._();
  @$core.override
  ListOrganizationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListOrganizationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListOrganizationsResponse>(create);
  static ListOrganizationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListOrganizationsResponse_Result whichResult() =>
      _ListOrganizationsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListOrganizations get organizations => $_getN(0);
  @$pb.TagNumber(1)
  set organizations(ListOrganizations value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganizations() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganizations() => $_clearField(1);
  @$pb.TagNumber(1)
  ListOrganizations ensureOrganizations() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

class ListOrganizations extends $pb.GeneratedMessage {
  factory ListOrganizations({
    $core.Iterable<$1.OrganizationData>? organizations,
  }) {
    final result = create();
    if (organizations != null) result.organizations.addAll(organizations);
    return result;
  }

  ListOrganizations._();

  factory ListOrganizations.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListOrganizations.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListOrganizations',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.OrganizationData>(1, _omitFieldNames ? '' : 'organizations',
        subBuilder: $1.OrganizationData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizations clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizations copyWith(void Function(ListOrganizations) updates) =>
      super.copyWith((message) => updates(message as ListOrganizations))
          as ListOrganizations;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListOrganizations create() => ListOrganizations._();
  @$core.override
  ListOrganizations createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListOrganizations getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListOrganizations>(create);
  static ListOrganizations? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.OrganizationData> get organizations => $_getList(0);
}

class CreateOrganizationRequest extends $pb.GeneratedMessage {
  factory CreateOrganizationRequest({
    $core.String? name,
    $core.String? iconUrl,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (iconUrl != null) result.iconUrl = iconUrl;
    return result;
  }

  CreateOrganizationRequest._();

  factory CreateOrganizationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateOrganizationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateOrganizationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'iconUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateOrganizationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateOrganizationRequest copyWith(
          void Function(CreateOrganizationRequest) updates) =>
      super.copyWith((message) => updates(message as CreateOrganizationRequest))
          as CreateOrganizationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateOrganizationRequest create() => CreateOrganizationRequest._();
  @$core.override
  CreateOrganizationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateOrganizationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateOrganizationRequest>(create);
  static CreateOrganizationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get iconUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set iconUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIconUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearIconUrl() => $_clearField(2);
}

enum CreateOrganizationResponse_Result { organization, error, notSet }

class CreateOrganizationResponse extends $pb.GeneratedMessage {
  factory CreateOrganizationResponse({
    $1.OrganizationData? organization,
    $0.Error? error,
  }) {
    final result = create();
    if (organization != null) result.organization = organization;
    if (error != null) result.error = error;
    return result;
  }

  CreateOrganizationResponse._();

  factory CreateOrganizationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateOrganizationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CreateOrganizationResponse_Result>
      _CreateOrganizationResponse_ResultByTag = {
    1: CreateOrganizationResponse_Result.organization,
    2: CreateOrganizationResponse_Result.error,
    0: CreateOrganizationResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateOrganizationResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.OrganizationData>(1, _omitFieldNames ? '' : 'organization',
        subBuilder: $1.OrganizationData.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateOrganizationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateOrganizationResponse copyWith(
          void Function(CreateOrganizationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CreateOrganizationResponse))
          as CreateOrganizationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateOrganizationResponse create() => CreateOrganizationResponse._();
  @$core.override
  CreateOrganizationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateOrganizationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateOrganizationResponse>(create);
  static CreateOrganizationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CreateOrganizationResponse_Result whichResult() =>
      _CreateOrganizationResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.OrganizationData get organization => $_getN(0);
  @$pb.TagNumber(1)
  set organization($1.OrganizationData value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganization() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganization() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.OrganizationData ensureOrganization() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

/// ListUserJoinRequestsRequest requests all pending join requests made by the user.
class ListUserJoinRequestsRequest extends $pb.GeneratedMessage {
  factory ListUserJoinRequestsRequest() => create();

  ListUserJoinRequestsRequest._();

  factory ListUserJoinRequestsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListUserJoinRequestsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListUserJoinRequestsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequestsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequestsRequest copyWith(
          void Function(ListUserJoinRequestsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListUserJoinRequestsRequest))
          as ListUserJoinRequestsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequestsRequest create() =>
      ListUserJoinRequestsRequest._();
  @$core.override
  ListUserJoinRequestsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequestsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListUserJoinRequestsRequest>(create);
  static ListUserJoinRequestsRequest? _defaultInstance;
}

enum ListUserJoinRequestsResponse_Result { requests, error, notSet }

/// ListUserJoinRequestsResponse contains all pending join requests made by the user.
class ListUserJoinRequestsResponse extends $pb.GeneratedMessage {
  factory ListUserJoinRequestsResponse({
    ListUserJoinRequests? requests,
    $0.Error? error,
  }) {
    final result = create();
    if (requests != null) result.requests = requests;
    if (error != null) result.error = error;
    return result;
  }

  ListUserJoinRequestsResponse._();

  factory ListUserJoinRequestsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListUserJoinRequestsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListUserJoinRequestsResponse_Result>
      _ListUserJoinRequestsResponse_ResultByTag = {
    1: ListUserJoinRequestsResponse_Result.requests,
    2: ListUserJoinRequestsResponse_Result.error,
    0: ListUserJoinRequestsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListUserJoinRequestsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListUserJoinRequests>(1, _omitFieldNames ? '' : 'requests',
        subBuilder: ListUserJoinRequests.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequestsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequestsResponse copyWith(
          void Function(ListUserJoinRequestsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListUserJoinRequestsResponse))
          as ListUserJoinRequestsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequestsResponse create() =>
      ListUserJoinRequestsResponse._();
  @$core.override
  ListUserJoinRequestsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequestsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListUserJoinRequestsResponse>(create);
  static ListUserJoinRequestsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListUserJoinRequestsResponse_Result whichResult() =>
      _ListUserJoinRequestsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListUserJoinRequests get requests => $_getN(0);
  @$pb.TagNumber(1)
  set requests(ListUserJoinRequests value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequests() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequests() => $_clearField(1);
  @$pb.TagNumber(1)
  ListUserJoinRequests ensureRequests() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

class ListUserJoinRequests extends $pb.GeneratedMessage {
  factory ListUserJoinRequests({
    $core.Iterable<$2.UserJoinRequest>? requests,
  }) {
    final result = create();
    if (requests != null) result.requests.addAll(requests);
    return result;
  }

  ListUserJoinRequests._();

  factory ListUserJoinRequests.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListUserJoinRequests.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListUserJoinRequests',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$2.UserJoinRequest>(1, _omitFieldNames ? '' : 'requests',
        subBuilder: $2.UserJoinRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequests clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListUserJoinRequests copyWith(void Function(ListUserJoinRequests) updates) =>
      super.copyWith((message) => updates(message as ListUserJoinRequests))
          as ListUserJoinRequests;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequests create() => ListUserJoinRequests._();
  @$core.override
  ListUserJoinRequests createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListUserJoinRequests getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListUserJoinRequests>(create);
  static ListUserJoinRequests? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$2.UserJoinRequest> get requests => $_getList(0);
}

/// RequestToJoinRequest creates a join request using a code.
class RequestToJoinRequest extends $pb.GeneratedMessage {
  factory RequestToJoinRequest({
    $core.String? code,
  }) {
    final result = create();
    if (code != null) result.code = code;
    return result;
  }

  RequestToJoinRequest._();

  factory RequestToJoinRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestToJoinRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestToJoinRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinRequest copyWith(void Function(RequestToJoinRequest) updates) =>
      super.copyWith((message) => updates(message as RequestToJoinRequest))
          as RequestToJoinRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestToJoinRequest create() => RequestToJoinRequest._();
  @$core.override
  RequestToJoinRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestToJoinRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestToJoinRequest>(create);
  static RequestToJoinRequest? _defaultInstance;

  /// The join code (e.g., "abc123")
  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

enum RequestToJoinResponse_Result { success, error, notSet }

/// RequestToJoinResponse returns either a pending request, auto-accepted membership, or an error.
class RequestToJoinResponse extends $pb.GeneratedMessage {
  factory RequestToJoinResponse({
    RequestToJoinResult? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  RequestToJoinResponse._();

  factory RequestToJoinResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestToJoinResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RequestToJoinResponse_Result>
      _RequestToJoinResponse_ResultByTag = {
    1: RequestToJoinResponse_Result.success,
    2: RequestToJoinResponse_Result.error,
    0: RequestToJoinResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestToJoinResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<RequestToJoinResult>(1, _omitFieldNames ? '' : 'success',
        subBuilder: RequestToJoinResult.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinResponse copyWith(
          void Function(RequestToJoinResponse) updates) =>
      super.copyWith((message) => updates(message as RequestToJoinResponse))
          as RequestToJoinResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestToJoinResponse create() => RequestToJoinResponse._();
  @$core.override
  RequestToJoinResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestToJoinResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestToJoinResponse>(create);
  static RequestToJoinResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  RequestToJoinResponse_Result whichResult() =>
      _RequestToJoinResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RequestToJoinResult get success => $_getN(0);
  @$pb.TagNumber(1)
  set success(RequestToJoinResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
  @$pb.TagNumber(1)
  RequestToJoinResult ensureSuccess() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

enum RequestToJoinResult_Outcome { request, member, notSet }

/// RequestToJoinResult contains either a pending request or immediate membership.
class RequestToJoinResult extends $pb.GeneratedMessage {
  factory RequestToJoinResult({
    $2.UserJoinRequest? request,
    AutoAcceptedMember? member,
  }) {
    final result = create();
    if (request != null) result.request = request;
    if (member != null) result.member = member;
    return result;
  }

  RequestToJoinResult._();

  factory RequestToJoinResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestToJoinResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RequestToJoinResult_Outcome>
      _RequestToJoinResult_OutcomeByTag = {
    1: RequestToJoinResult_Outcome.request,
    2: RequestToJoinResult_Outcome.member,
    0: RequestToJoinResult_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestToJoinResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$2.UserJoinRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: $2.UserJoinRequest.create)
    ..aOM<AutoAcceptedMember>(2, _omitFieldNames ? '' : 'member',
        subBuilder: AutoAcceptedMember.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestToJoinResult copyWith(void Function(RequestToJoinResult) updates) =>
      super.copyWith((message) => updates(message as RequestToJoinResult))
          as RequestToJoinResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestToJoinResult create() => RequestToJoinResult._();
  @$core.override
  RequestToJoinResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestToJoinResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestToJoinResult>(create);
  static RequestToJoinResult? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  RequestToJoinResult_Outcome whichOutcome() =>
      _RequestToJoinResult_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  /// User has a pending request awaiting approval
  @$pb.TagNumber(1)
  $2.UserJoinRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request($2.UserJoinRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.UserJoinRequest ensureRequest() => $_ensure(0);

  /// User was auto-accepted and is now a member
  @$pb.TagNumber(2)
  AutoAcceptedMember get member => $_getN(1);
  @$pb.TagNumber(2)
  set member(AutoAcceptedMember value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMember() => $_has(1);
  @$pb.TagNumber(2)
  void clearMember() => $_clearField(2);
  @$pb.TagNumber(2)
  AutoAcceptedMember ensureMember() => $_ensure(1);
}

/// AutoAcceptedMember represents immediate membership after using an auto-accept code.
class AutoAcceptedMember extends $pb.GeneratedMessage {
  factory AutoAcceptedMember({
    $core.String? organizationId,
    $core.String? organizationName,
    $core.String? organizationIconUrl,
    $core.Iterable<$3.Role>? roles,
  }) {
    final result = create();
    if (organizationId != null) result.organizationId = organizationId;
    if (organizationName != null) result.organizationName = organizationName;
    if (organizationIconUrl != null)
      result.organizationIconUrl = organizationIconUrl;
    if (roles != null) result.roles.addAll(roles);
    return result;
  }

  AutoAcceptedMember._();

  factory AutoAcceptedMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AutoAcceptedMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AutoAcceptedMember',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'organizationId')
    ..aOS(2, _omitFieldNames ? '' : 'organizationName')
    ..aOS(3, _omitFieldNames ? '' : 'organizationIconUrl')
    ..pPM<$3.Role>(4, _omitFieldNames ? '' : 'roles',
        subBuilder: $3.Role.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutoAcceptedMember clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutoAcceptedMember copyWith(void Function(AutoAcceptedMember) updates) =>
      super.copyWith((message) => updates(message as AutoAcceptedMember))
          as AutoAcceptedMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AutoAcceptedMember create() => AutoAcceptedMember._();
  @$core.override
  AutoAcceptedMember createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AutoAcceptedMember getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AutoAcceptedMember>(create);
  static AutoAcceptedMember? _defaultInstance;

  /// Organization ID the user joined
  @$pb.TagNumber(1)
  $core.String get organizationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set organizationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganizationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganizationId() => $_clearField(1);

  /// Organization name
  @$pb.TagNumber(2)
  $core.String get organizationName => $_getSZ(1);
  @$pb.TagNumber(2)
  set organizationName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrganizationName() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrganizationName() => $_clearField(2);

  /// Organization icon URL
  @$pb.TagNumber(3)
  $core.String get organizationIconUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set organizationIconUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOrganizationIconUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrganizationIconUrl() => $_clearField(3);

  /// Roles assigned to the user
  @$pb.TagNumber(4)
  $pb.PbList<$3.Role> get roles => $_getList(3);
}

/// CancelJoinRequestRequest cancels a pending join request.
class CancelJoinRequestRequest extends $pb.GeneratedMessage {
  factory CancelJoinRequestRequest({
    $core.String? requestId,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    return result;
  }

  CancelJoinRequestRequest._();

  factory CancelJoinRequestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelJoinRequestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelJoinRequestRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelJoinRequestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelJoinRequestRequest copyWith(
          void Function(CancelJoinRequestRequest) updates) =>
      super.copyWith((message) => updates(message as CancelJoinRequestRequest))
          as CancelJoinRequestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelJoinRequestRequest create() => CancelJoinRequestRequest._();
  @$core.override
  CancelJoinRequestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelJoinRequestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelJoinRequestRequest>(create);
  static CancelJoinRequestRequest? _defaultInstance;

  /// Unique identifier of the join request to cancel
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);
}

enum CancelJoinRequestResponse_Result { success, error, notSet }

/// CancelJoinRequestResponse indicates success or returns an error.
class CancelJoinRequestResponse extends $pb.GeneratedMessage {
  factory CancelJoinRequestResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  CancelJoinRequestResponse._();

  factory CancelJoinRequestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelJoinRequestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CancelJoinRequestResponse_Result>
      _CancelJoinRequestResponse_ResultByTag = {
    1: CancelJoinRequestResponse_Result.success,
    2: CancelJoinRequestResponse_Result.error,
    0: CancelJoinRequestResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelJoinRequestResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelJoinRequestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelJoinRequestResponse copyWith(
          void Function(CancelJoinRequestResponse) updates) =>
      super.copyWith((message) => updates(message as CancelJoinRequestResponse))
          as CancelJoinRequestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelJoinRequestResponse create() => CancelJoinRequestResponse._();
  @$core.override
  CancelJoinRequestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelJoinRequestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelJoinRequestResponse>(create);
  static CancelJoinRequestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CancelJoinRequestResponse_Result whichResult() =>
      _CancelJoinRequestResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
