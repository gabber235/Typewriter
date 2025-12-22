// This is a generated file - do not edit.
//
// Generated from api/organization/member.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../models/common.pb.dart' as $0;
import '../../models/organization/member.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// ListMembersRequest requests all members in the organization.
class ListMembersRequest extends $pb.GeneratedMessage {
  factory ListMembersRequest() => create();

  ListMembersRequest._();

  factory ListMembersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListMembersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMembersRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembersRequest copyWith(void Function(ListMembersRequest) updates) =>
      super.copyWith((message) => updates(message as ListMembersRequest))
          as ListMembersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListMembersRequest create() => ListMembersRequest._();
  @$core.override
  ListMembersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListMembersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMembersRequest>(create);
  static ListMembersRequest? _defaultInstance;
}

enum ListMembersResponse_Result { members, error, notSet }

/// ListMembersResponse contains all members in the organization.
class ListMembersResponse extends $pb.GeneratedMessage {
  factory ListMembersResponse({
    ListMembers? members,
    $0.Error? error,
  }) {
    final result = create();
    if (members != null) result.members = members;
    if (error != null) result.error = error;
    return result;
  }

  ListMembersResponse._();

  factory ListMembersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListMembersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListMembersResponse_Result>
      _ListMembersResponse_ResultByTag = {
    1: ListMembersResponse_Result.members,
    2: ListMembersResponse_Result.error,
    0: ListMembersResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMembersResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListMembers>(1, _omitFieldNames ? '' : 'members',
        subBuilder: ListMembers.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembersResponse copyWith(void Function(ListMembersResponse) updates) =>
      super.copyWith((message) => updates(message as ListMembersResponse))
          as ListMembersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListMembersResponse create() => ListMembersResponse._();
  @$core.override
  ListMembersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListMembersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMembersResponse>(create);
  static ListMembersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListMembersResponse_Result whichResult() =>
      _ListMembersResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListMembers get members => $_getN(0);
  @$pb.TagNumber(1)
  set members(ListMembers value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMembers() => $_has(0);
  @$pb.TagNumber(1)
  void clearMembers() => $_clearField(1);
  @$pb.TagNumber(1)
  ListMembers ensureMembers() => $_ensure(0);

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

class ListMembers extends $pb.GeneratedMessage {
  factory ListMembers({
    $core.Iterable<$1.OrganizationMember>? members,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    return result;
  }

  ListMembers._();

  factory ListMembers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListMembers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMembers',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.OrganizationMember>(1, _omitFieldNames ? '' : 'members',
        subBuilder: $1.OrganizationMember.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembers clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMembers copyWith(void Function(ListMembers) updates) =>
      super.copyWith((message) => updates(message as ListMembers))
          as ListMembers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListMembers create() => ListMembers._();
  @$core.override
  ListMembers createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListMembers getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMembers>(create);
  static ListMembers? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.OrganizationMember> get members => $_getList(0);
}

/// UpdateMemberRolesRequest updates the roles assigned to a member.
class UpdateMemberRolesRequest extends $pb.GeneratedMessage {
  factory UpdateMemberRolesRequest({
    $core.String? memberId,
    $core.Iterable<$core.String>? roleIds,
  }) {
    final result = create();
    if (memberId != null) result.memberId = memberId;
    if (roleIds != null) result.roleIds.addAll(roleIds);
    return result;
  }

  UpdateMemberRolesRequest._();

  factory UpdateMemberRolesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateMemberRolesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMemberRolesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'memberId')
    ..pPS(2, _omitFieldNames ? '' : 'roleIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemberRolesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemberRolesRequest copyWith(
          void Function(UpdateMemberRolesRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateMemberRolesRequest))
          as UpdateMemberRolesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateMemberRolesRequest create() => UpdateMemberRolesRequest._();
  @$core.override
  UpdateMemberRolesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateMemberRolesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMemberRolesRequest>(create);
  static UpdateMemberRolesRequest? _defaultInstance;

  /// Unique identifier of the member to update
  @$pb.TagNumber(1)
  $core.String get memberId => $_getSZ(0);
  @$pb.TagNumber(1)
  set memberId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberId() => $_clearField(1);

  /// List of role IDs to assign to the member
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get roleIds => $_getList(1);
}

enum UpdateMemberRolesResponse_Result { member, error, notSet }

/// UpdateMemberRolesResponse returns the updated member or an error.
class UpdateMemberRolesResponse extends $pb.GeneratedMessage {
  factory UpdateMemberRolesResponse({
    $1.OrganizationMember? member,
    $0.Error? error,
  }) {
    final result = create();
    if (member != null) result.member = member;
    if (error != null) result.error = error;
    return result;
  }

  UpdateMemberRolesResponse._();

  factory UpdateMemberRolesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateMemberRolesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateMemberRolesResponse_Result>
      _UpdateMemberRolesResponse_ResultByTag = {
    1: UpdateMemberRolesResponse_Result.member,
    2: UpdateMemberRolesResponse_Result.error,
    0: UpdateMemberRolesResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMemberRolesResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.OrganizationMember>(1, _omitFieldNames ? '' : 'member',
        subBuilder: $1.OrganizationMember.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemberRolesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemberRolesResponse copyWith(
          void Function(UpdateMemberRolesResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateMemberRolesResponse))
          as UpdateMemberRolesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateMemberRolesResponse create() => UpdateMemberRolesResponse._();
  @$core.override
  UpdateMemberRolesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateMemberRolesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMemberRolesResponse>(create);
  static UpdateMemberRolesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UpdateMemberRolesResponse_Result whichResult() =>
      _UpdateMemberRolesResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.OrganizationMember get member => $_getN(0);
  @$pb.TagNumber(1)
  set member($1.OrganizationMember value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMember() => $_has(0);
  @$pb.TagNumber(1)
  void clearMember() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.OrganizationMember ensureMember() => $_ensure(0);

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

/// RemoveMemberRequest removes a member from the organization.
class RemoveMemberRequest extends $pb.GeneratedMessage {
  factory RemoveMemberRequest({
    $core.String? memberId,
  }) {
    final result = create();
    if (memberId != null) result.memberId = memberId;
    return result;
  }

  RemoveMemberRequest._();

  factory RemoveMemberRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveMemberRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveMemberRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'memberId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberRequest copyWith(void Function(RemoveMemberRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveMemberRequest))
          as RemoveMemberRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveMemberRequest create() => RemoveMemberRequest._();
  @$core.override
  RemoveMemberRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveMemberRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveMemberRequest>(create);
  static RemoveMemberRequest? _defaultInstance;

  /// Unique identifier of the member to remove
  @$pb.TagNumber(1)
  $core.String get memberId => $_getSZ(0);
  @$pb.TagNumber(1)
  set memberId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberId() => $_clearField(1);
}

enum RemoveMemberResponse_Result { success, error, notSet }

/// RemoveMemberResponse indicates success or returns an error.
class RemoveMemberResponse extends $pb.GeneratedMessage {
  factory RemoveMemberResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  RemoveMemberResponse._();

  factory RemoveMemberResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveMemberResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RemoveMemberResponse_Result>
      _RemoveMemberResponse_ResultByTag = {
    1: RemoveMemberResponse_Result.success,
    2: RemoveMemberResponse_Result.error,
    0: RemoveMemberResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveMemberResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveMemberResponse copyWith(void Function(RemoveMemberResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveMemberResponse))
          as RemoveMemberResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveMemberResponse create() => RemoveMemberResponse._();
  @$core.override
  RemoveMemberResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveMemberResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveMemberResponse>(create);
  static RemoveMemberResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  RemoveMemberResponse_Result whichResult() =>
      _RemoveMemberResponse_ResultByTag[$_whichOneof(0)]!;
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

/// ListJoinRequestsRequest requests all pending join requests to the organization.
class ListJoinRequestsRequest extends $pb.GeneratedMessage {
  factory ListJoinRequestsRequest() => create();

  ListJoinRequestsRequest._();

  factory ListJoinRequestsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinRequestsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinRequestsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequestsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequestsRequest copyWith(
          void Function(ListJoinRequestsRequest) updates) =>
      super.copyWith((message) => updates(message as ListJoinRequestsRequest))
          as ListJoinRequestsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinRequestsRequest create() => ListJoinRequestsRequest._();
  @$core.override
  ListJoinRequestsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinRequestsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinRequestsRequest>(create);
  static ListJoinRequestsRequest? _defaultInstance;
}

enum ListJoinRequestsResponse_Result { requests, error, notSet }

/// ListJoinRequestsResponse contains all pending join requests.
class ListJoinRequestsResponse extends $pb.GeneratedMessage {
  factory ListJoinRequestsResponse({
    ListJoinRequests? requests,
    $0.Error? error,
  }) {
    final result = create();
    if (requests != null) result.requests = requests;
    if (error != null) result.error = error;
    return result;
  }

  ListJoinRequestsResponse._();

  factory ListJoinRequestsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinRequestsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListJoinRequestsResponse_Result>
      _ListJoinRequestsResponse_ResultByTag = {
    1: ListJoinRequestsResponse_Result.requests,
    2: ListJoinRequestsResponse_Result.error,
    0: ListJoinRequestsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinRequestsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListJoinRequests>(1, _omitFieldNames ? '' : 'requests',
        subBuilder: ListJoinRequests.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequestsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequestsResponse copyWith(
          void Function(ListJoinRequestsResponse) updates) =>
      super.copyWith((message) => updates(message as ListJoinRequestsResponse))
          as ListJoinRequestsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinRequestsResponse create() => ListJoinRequestsResponse._();
  @$core.override
  ListJoinRequestsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinRequestsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinRequestsResponse>(create);
  static ListJoinRequestsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListJoinRequestsResponse_Result whichResult() =>
      _ListJoinRequestsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListJoinRequests get requests => $_getN(0);
  @$pb.TagNumber(1)
  set requests(ListJoinRequests value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequests() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequests() => $_clearField(1);
  @$pb.TagNumber(1)
  ListJoinRequests ensureRequests() => $_ensure(0);

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

class ListJoinRequests extends $pb.GeneratedMessage {
  factory ListJoinRequests({
    $core.Iterable<$1.JoinRequest>? requests,
  }) {
    final result = create();
    if (requests != null) result.requests.addAll(requests);
    return result;
  }

  ListJoinRequests._();

  factory ListJoinRequests.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinRequests.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinRequests',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.JoinRequest>(1, _omitFieldNames ? '' : 'requests',
        subBuilder: $1.JoinRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequests clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinRequests copyWith(void Function(ListJoinRequests) updates) =>
      super.copyWith((message) => updates(message as ListJoinRequests))
          as ListJoinRequests;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinRequests create() => ListJoinRequests._();
  @$core.override
  ListJoinRequests createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinRequests getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinRequests>(create);
  static ListJoinRequests? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.JoinRequest> get requests => $_getList(0);
}

/// ApproveJoinRequestRequest approves a pending join request and assigns roles.
class ApproveJoinRequestRequest extends $pb.GeneratedMessage {
  factory ApproveJoinRequestRequest({
    $core.String? requestId,
    $core.Iterable<$core.String>? roleIds,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (roleIds != null) result.roleIds.addAll(roleIds);
    return result;
  }

  ApproveJoinRequestRequest._();

  factory ApproveJoinRequestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApproveJoinRequestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApproveJoinRequestRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..pPS(2, _omitFieldNames ? '' : 'roleIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveJoinRequestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveJoinRequestRequest copyWith(
          void Function(ApproveJoinRequestRequest) updates) =>
      super.copyWith((message) => updates(message as ApproveJoinRequestRequest))
          as ApproveJoinRequestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApproveJoinRequestRequest create() => ApproveJoinRequestRequest._();
  @$core.override
  ApproveJoinRequestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApproveJoinRequestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApproveJoinRequestRequest>(create);
  static ApproveJoinRequestRequest? _defaultInstance;

  /// Unique identifier of the join request to approve
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  /// List of role IDs to assign to the new member
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get roleIds => $_getList(1);
}

enum ApproveJoinRequestResponse_Result { member, error, notSet }

/// ApproveJoinRequestResponse returns the new member or an error.
class ApproveJoinRequestResponse extends $pb.GeneratedMessage {
  factory ApproveJoinRequestResponse({
    $1.OrganizationMember? member,
    $0.Error? error,
  }) {
    final result = create();
    if (member != null) result.member = member;
    if (error != null) result.error = error;
    return result;
  }

  ApproveJoinRequestResponse._();

  factory ApproveJoinRequestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApproveJoinRequestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ApproveJoinRequestResponse_Result>
      _ApproveJoinRequestResponse_ResultByTag = {
    1: ApproveJoinRequestResponse_Result.member,
    2: ApproveJoinRequestResponse_Result.error,
    0: ApproveJoinRequestResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApproveJoinRequestResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.OrganizationMember>(1, _omitFieldNames ? '' : 'member',
        subBuilder: $1.OrganizationMember.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveJoinRequestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveJoinRequestResponse copyWith(
          void Function(ApproveJoinRequestResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ApproveJoinRequestResponse))
          as ApproveJoinRequestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApproveJoinRequestResponse create() => ApproveJoinRequestResponse._();
  @$core.override
  ApproveJoinRequestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApproveJoinRequestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApproveJoinRequestResponse>(create);
  static ApproveJoinRequestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ApproveJoinRequestResponse_Result whichResult() =>
      _ApproveJoinRequestResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.OrganizationMember get member => $_getN(0);
  @$pb.TagNumber(1)
  set member($1.OrganizationMember value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMember() => $_has(0);
  @$pb.TagNumber(1)
  void clearMember() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.OrganizationMember ensureMember() => $_ensure(0);

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

/// DeclineJoinRequestRequest declines a pending join request.
class DeclineJoinRequestRequest extends $pb.GeneratedMessage {
  factory DeclineJoinRequestRequest({
    $core.String? requestId,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    return result;
  }

  DeclineJoinRequestRequest._();

  factory DeclineJoinRequestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeclineJoinRequestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeclineJoinRequestRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeclineJoinRequestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeclineJoinRequestRequest copyWith(
          void Function(DeclineJoinRequestRequest) updates) =>
      super.copyWith((message) => updates(message as DeclineJoinRequestRequest))
          as DeclineJoinRequestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeclineJoinRequestRequest create() => DeclineJoinRequestRequest._();
  @$core.override
  DeclineJoinRequestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeclineJoinRequestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeclineJoinRequestRequest>(create);
  static DeclineJoinRequestRequest? _defaultInstance;

  /// Unique identifier of the join request to decline
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);
}

enum DeclineJoinRequestResponse_Result { success, error, notSet }

/// DeclineJoinRequestResponse indicates success or returns an error.
class DeclineJoinRequestResponse extends $pb.GeneratedMessage {
  factory DeclineJoinRequestResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeclineJoinRequestResponse._();

  factory DeclineJoinRequestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeclineJoinRequestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeclineJoinRequestResponse_Result>
      _DeclineJoinRequestResponse_ResultByTag = {
    1: DeclineJoinRequestResponse_Result.success,
    2: DeclineJoinRequestResponse_Result.error,
    0: DeclineJoinRequestResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeclineJoinRequestResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeclineJoinRequestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeclineJoinRequestResponse copyWith(
          void Function(DeclineJoinRequestResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DeclineJoinRequestResponse))
          as DeclineJoinRequestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeclineJoinRequestResponse create() => DeclineJoinRequestResponse._();
  @$core.override
  DeclineJoinRequestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeclineJoinRequestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeclineJoinRequestResponse>(create);
  static DeclineJoinRequestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeclineJoinRequestResponse_Result whichResult() =>
      _DeclineJoinRequestResponse_ResultByTag[$_whichOneof(0)]!;
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

/// GenerateJoinCodeRequest generates a new join code for the organization.
class GenerateJoinCodeRequest extends $pb.GeneratedMessage {
  factory GenerateJoinCodeRequest() => create();

  GenerateJoinCodeRequest._();

  factory GenerateJoinCodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateJoinCodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateJoinCodeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateJoinCodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateJoinCodeRequest copyWith(
          void Function(GenerateJoinCodeRequest) updates) =>
      super.copyWith((message) => updates(message as GenerateJoinCodeRequest))
          as GenerateJoinCodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateJoinCodeRequest create() => GenerateJoinCodeRequest._();
  @$core.override
  GenerateJoinCodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateJoinCodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateJoinCodeRequest>(create);
  static GenerateJoinCodeRequest? _defaultInstance;
}

enum GenerateJoinCodeResponse_Result { joinCode, error, notSet }

/// GenerateJoinCodeResponse returns the generated join code or an error.
class GenerateJoinCodeResponse extends $pb.GeneratedMessage {
  factory GenerateJoinCodeResponse({
    $1.JoinCode? joinCode,
    $0.Error? error,
  }) {
    final result = create();
    if (joinCode != null) result.joinCode = joinCode;
    if (error != null) result.error = error;
    return result;
  }

  GenerateJoinCodeResponse._();

  factory GenerateJoinCodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateJoinCodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GenerateJoinCodeResponse_Result>
      _GenerateJoinCodeResponse_ResultByTag = {
    1: GenerateJoinCodeResponse_Result.joinCode,
    2: GenerateJoinCodeResponse_Result.error,
    0: GenerateJoinCodeResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateJoinCodeResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.JoinCode>(1, _omitFieldNames ? '' : 'joinCode',
        subBuilder: $1.JoinCode.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateJoinCodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateJoinCodeResponse copyWith(
          void Function(GenerateJoinCodeResponse) updates) =>
      super.copyWith((message) => updates(message as GenerateJoinCodeResponse))
          as GenerateJoinCodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateJoinCodeResponse create() => GenerateJoinCodeResponse._();
  @$core.override
  GenerateJoinCodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateJoinCodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateJoinCodeResponse>(create);
  static GenerateJoinCodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GenerateJoinCodeResponse_Result whichResult() =>
      _GenerateJoinCodeResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.JoinCode get joinCode => $_getN(0);
  @$pb.TagNumber(1)
  set joinCode($1.JoinCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasJoinCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoinCode() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.JoinCode ensureJoinCode() => $_ensure(0);

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

/// ListJoinCodesRequest requests all active join codes for the organization.
class ListJoinCodesRequest extends $pb.GeneratedMessage {
  factory ListJoinCodesRequest() => create();

  ListJoinCodesRequest._();

  factory ListJoinCodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinCodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinCodesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodesRequest copyWith(void Function(ListJoinCodesRequest) updates) =>
      super.copyWith((message) => updates(message as ListJoinCodesRequest))
          as ListJoinCodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinCodesRequest create() => ListJoinCodesRequest._();
  @$core.override
  ListJoinCodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinCodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinCodesRequest>(create);
  static ListJoinCodesRequest? _defaultInstance;
}

enum ListJoinCodesResponse_Result { joinCodes, error, notSet }

/// ListJoinCodesResponse contains all active join codes.
class ListJoinCodesResponse extends $pb.GeneratedMessage {
  factory ListJoinCodesResponse({
    ListJoinCodes? joinCodes,
    $0.Error? error,
  }) {
    final result = create();
    if (joinCodes != null) result.joinCodes = joinCodes;
    if (error != null) result.error = error;
    return result;
  }

  ListJoinCodesResponse._();

  factory ListJoinCodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinCodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListJoinCodesResponse_Result>
      _ListJoinCodesResponse_ResultByTag = {
    1: ListJoinCodesResponse_Result.joinCodes,
    2: ListJoinCodesResponse_Result.error,
    0: ListJoinCodesResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinCodesResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListJoinCodes>(1, _omitFieldNames ? '' : 'joinCodes',
        subBuilder: ListJoinCodes.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodesResponse copyWith(
          void Function(ListJoinCodesResponse) updates) =>
      super.copyWith((message) => updates(message as ListJoinCodesResponse))
          as ListJoinCodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinCodesResponse create() => ListJoinCodesResponse._();
  @$core.override
  ListJoinCodesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinCodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinCodesResponse>(create);
  static ListJoinCodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListJoinCodesResponse_Result whichResult() =>
      _ListJoinCodesResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListJoinCodes get joinCodes => $_getN(0);
  @$pb.TagNumber(1)
  set joinCodes(ListJoinCodes value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasJoinCodes() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoinCodes() => $_clearField(1);
  @$pb.TagNumber(1)
  ListJoinCodes ensureJoinCodes() => $_ensure(0);

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

class ListJoinCodes extends $pb.GeneratedMessage {
  factory ListJoinCodes({
    $core.Iterable<$1.JoinCode>? joinCodes,
  }) {
    final result = create();
    if (joinCodes != null) result.joinCodes.addAll(joinCodes);
    return result;
  }

  ListJoinCodes._();

  factory ListJoinCodes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListJoinCodes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListJoinCodes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.JoinCode>(1, _omitFieldNames ? '' : 'joinCodes',
        subBuilder: $1.JoinCode.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListJoinCodes copyWith(void Function(ListJoinCodes) updates) =>
      super.copyWith((message) => updates(message as ListJoinCodes))
          as ListJoinCodes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListJoinCodes create() => ListJoinCodes._();
  @$core.override
  ListJoinCodes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListJoinCodes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListJoinCodes>(create);
  static ListJoinCodes? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.JoinCode> get joinCodes => $_getList(0);
}

/// RevokeJoinCodeRequest revokes a join code.
class RevokeJoinCodeRequest extends $pb.GeneratedMessage {
  factory RevokeJoinCodeRequest({
    $core.String? codeId,
  }) {
    final result = create();
    if (codeId != null) result.codeId = codeId;
    return result;
  }

  RevokeJoinCodeRequest._();

  factory RevokeJoinCodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeJoinCodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeJoinCodeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'codeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeJoinCodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeJoinCodeRequest copyWith(
          void Function(RevokeJoinCodeRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeJoinCodeRequest))
          as RevokeJoinCodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeJoinCodeRequest create() => RevokeJoinCodeRequest._();
  @$core.override
  RevokeJoinCodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeJoinCodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeJoinCodeRequest>(create);
  static RevokeJoinCodeRequest? _defaultInstance;

  /// Unique identifier of the join code to revoke
  @$pb.TagNumber(1)
  $core.String get codeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set codeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCodeId() => $_clearField(1);
}

enum RevokeJoinCodeResponse_Result { success, error, notSet }

/// RevokeJoinCodeResponse indicates success or returns an error.
class RevokeJoinCodeResponse extends $pb.GeneratedMessage {
  factory RevokeJoinCodeResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  RevokeJoinCodeResponse._();

  factory RevokeJoinCodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeJoinCodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RevokeJoinCodeResponse_Result>
      _RevokeJoinCodeResponse_ResultByTag = {
    1: RevokeJoinCodeResponse_Result.success,
    2: RevokeJoinCodeResponse_Result.error,
    0: RevokeJoinCodeResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeJoinCodeResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeJoinCodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeJoinCodeResponse copyWith(
          void Function(RevokeJoinCodeResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeJoinCodeResponse))
          as RevokeJoinCodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeJoinCodeResponse create() => RevokeJoinCodeResponse._();
  @$core.override
  RevokeJoinCodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeJoinCodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeJoinCodeResponse>(create);
  static RevokeJoinCodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  RevokeJoinCodeResponse_Result whichResult() =>
      _RevokeJoinCodeResponse_ResultByTag[$_whichOneof(0)]!;
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
