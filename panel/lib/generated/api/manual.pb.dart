// This is a generated file - do not edit.
//
// Generated from api/manual.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/common.pb.dart' as $1;
import '../models/manual.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListManualsRequest extends $pb.GeneratedMessage {
  factory ListManualsRequest() => create();

  ListManualsRequest._();

  factory ListManualsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListManualsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListManualsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListManualsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListManualsRequest copyWith(void Function(ListManualsRequest) updates) =>
      super.copyWith((message) => updates(message as ListManualsRequest))
          as ListManualsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListManualsRequest create() => ListManualsRequest._();
  @$core.override
  ListManualsRequest createEmptyInstance() => create();
  static $pb.PbList<ListManualsRequest> createRepeated() =>
      $pb.PbList<ListManualsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListManualsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListManualsRequest>(create);
  static ListManualsRequest? _defaultInstance;
}

class ListManualsResponse extends $pb.GeneratedMessage {
  factory ListManualsResponse({
    $core.Iterable<$0.Manual>? manuals,
  }) {
    final result = create();
    if (manuals != null) result.manuals.addAll(manuals);
    return result;
  }

  ListManualsResponse._();

  factory ListManualsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListManualsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListManualsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Manual>(1, _omitFieldNames ? '' : 'manuals',
        subBuilder: $0.Manual.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListManualsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListManualsResponse copyWith(void Function(ListManualsResponse) updates) =>
      super.copyWith((message) => updates(message as ListManualsResponse))
          as ListManualsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListManualsResponse create() => ListManualsResponse._();
  @$core.override
  ListManualsResponse createEmptyInstance() => create();
  static $pb.PbList<ListManualsResponse> createRepeated() =>
      $pb.PbList<ListManualsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListManualsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListManualsResponse>(create);
  static ListManualsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Manual> get manuals => $_getList(0);
}

class GetManualRequest extends $pb.GeneratedMessage {
  factory GetManualRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetManualRequest._();

  factory GetManualRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetManualRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetManualRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetManualRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetManualRequest copyWith(void Function(GetManualRequest) updates) =>
      super.copyWith((message) => updates(message as GetManualRequest))
          as GetManualRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetManualRequest create() => GetManualRequest._();
  @$core.override
  GetManualRequest createEmptyInstance() => create();
  static $pb.PbList<GetManualRequest> createRepeated() =>
      $pb.PbList<GetManualRequest>();
  @$core.pragma('dart2js:noInline')
  static GetManualRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetManualRequest>(create);
  static GetManualRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum GetManualResponse_Result { manual, error, notSet }

class GetManualResponse extends $pb.GeneratedMessage {
  factory GetManualResponse({
    $0.Manual? manual,
    $1.Error? error,
  }) {
    final result = create();
    if (manual != null) result.manual = manual;
    if (error != null) result.error = error;
    return result;
  }

  GetManualResponse._();

  factory GetManualResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetManualResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetManualResponse_Result>
      _GetManualResponse_ResultByTag = {
    1: GetManualResponse_Result.manual,
    2: GetManualResponse_Result.error,
    0: GetManualResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetManualResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Manual>(1, _omitFieldNames ? '' : 'manual',
        subBuilder: $0.Manual.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetManualResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetManualResponse copyWith(void Function(GetManualResponse) updates) =>
      super.copyWith((message) => updates(message as GetManualResponse))
          as GetManualResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetManualResponse create() => GetManualResponse._();
  @$core.override
  GetManualResponse createEmptyInstance() => create();
  static $pb.PbList<GetManualResponse> createRepeated() =>
      $pb.PbList<GetManualResponse>();
  @$core.pragma('dart2js:noInline')
  static GetManualResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetManualResponse>(create);
  static GetManualResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetManualResponse_Result whichResult() =>
      _GetManualResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Manual get manual => $_getN(0);
  @$pb.TagNumber(1)
  set manual($0.Manual value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasManual() => $_has(0);
  @$pb.TagNumber(1)
  void clearManual() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Manual ensureManual() => $_ensure(0);

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

class CreateManualRequest extends $pb.GeneratedMessage {
  factory CreateManualRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  CreateManualRequest._();

  factory CreateManualRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateManualRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateManualRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateManualRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateManualRequest copyWith(void Function(CreateManualRequest) updates) =>
      super.copyWith((message) => updates(message as CreateManualRequest))
          as CreateManualRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateManualRequest create() => CreateManualRequest._();
  @$core.override
  CreateManualRequest createEmptyInstance() => create();
  static $pb.PbList<CreateManualRequest> createRepeated() =>
      $pb.PbList<CreateManualRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateManualRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateManualRequest>(create);
  static CreateManualRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

enum CreateManualResponse_Result { manual, error, notSet }

class CreateManualResponse extends $pb.GeneratedMessage {
  factory CreateManualResponse({
    $0.Manual? manual,
    $1.Error? error,
  }) {
    final result = create();
    if (manual != null) result.manual = manual;
    if (error != null) result.error = error;
    return result;
  }

  CreateManualResponse._();

  factory CreateManualResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateManualResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CreateManualResponse_Result>
      _CreateManualResponse_ResultByTag = {
    1: CreateManualResponse_Result.manual,
    2: CreateManualResponse_Result.error,
    0: CreateManualResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateManualResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Manual>(1, _omitFieldNames ? '' : 'manual',
        subBuilder: $0.Manual.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateManualResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateManualResponse copyWith(void Function(CreateManualResponse) updates) =>
      super.copyWith((message) => updates(message as CreateManualResponse))
          as CreateManualResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateManualResponse create() => CreateManualResponse._();
  @$core.override
  CreateManualResponse createEmptyInstance() => create();
  static $pb.PbList<CreateManualResponse> createRepeated() =>
      $pb.PbList<CreateManualResponse>();
  @$core.pragma('dart2js:noInline')
  static CreateManualResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateManualResponse>(create);
  static CreateManualResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CreateManualResponse_Result whichResult() =>
      _CreateManualResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Manual get manual => $_getN(0);
  @$pb.TagNumber(1)
  set manual($0.Manual value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasManual() => $_has(0);
  @$pb.TagNumber(1)
  void clearManual() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Manual ensureManual() => $_ensure(0);

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

class DeleteManualRequest extends $pb.GeneratedMessage {
  factory DeleteManualRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteManualRequest._();

  factory DeleteManualRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteManualRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteManualRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteManualRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteManualRequest copyWith(void Function(DeleteManualRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteManualRequest))
          as DeleteManualRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteManualRequest create() => DeleteManualRequest._();
  @$core.override
  DeleteManualRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteManualRequest> createRepeated() =>
      $pb.PbList<DeleteManualRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteManualRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteManualRequest>(create);
  static DeleteManualRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum DeleteManualResponse_Result { success, error, notSet }

class DeleteManualResponse extends $pb.GeneratedMessage {
  factory DeleteManualResponse({
    $core.bool? success,
    $1.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteManualResponse._();

  factory DeleteManualResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteManualResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeleteManualResponse_Result>
      _DeleteManualResponse_ResultByTag = {
    1: DeleteManualResponse_Result.success,
    2: DeleteManualResponse_Result.error,
    0: DeleteManualResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteManualResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteManualResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteManualResponse copyWith(void Function(DeleteManualResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteManualResponse))
          as DeleteManualResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteManualResponse create() => DeleteManualResponse._();
  @$core.override
  DeleteManualResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteManualResponse> createRepeated() =>
      $pb.PbList<DeleteManualResponse>();
  @$core.pragma('dart2js:noInline')
  static DeleteManualResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteManualResponse>(create);
  static DeleteManualResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeleteManualResponse_Result whichResult() =>
      _DeleteManualResponse_ResultByTag[$_whichOneof(0)]!;
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

class ChangePlatformTargetsRequest extends $pb.GeneratedMessage {
  factory ChangePlatformTargetsRequest({
    $core.String? manualId,
    $core.Iterable<$0.PlatformTarget>? proposed,
  }) {
    final result = create();
    if (manualId != null) result.manualId = manualId;
    if (proposed != null) result.proposed.addAll(proposed);
    return result;
  }

  ChangePlatformTargetsRequest._();

  factory ChangePlatformTargetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePlatformTargetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePlatformTargetsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'manualId')
    ..pPM<$0.PlatformTarget>(2, _omitFieldNames ? '' : 'proposed',
        subBuilder: $0.PlatformTarget.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePlatformTargetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePlatformTargetsRequest copyWith(
          void Function(ChangePlatformTargetsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ChangePlatformTargetsRequest))
          as ChangePlatformTargetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePlatformTargetsRequest create() =>
      ChangePlatformTargetsRequest._();
  @$core.override
  ChangePlatformTargetsRequest createEmptyInstance() => create();
  static $pb.PbList<ChangePlatformTargetsRequest> createRepeated() =>
      $pb.PbList<ChangePlatformTargetsRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangePlatformTargetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePlatformTargetsRequest>(create);
  static ChangePlatformTargetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get manualId => $_getSZ(0);
  @$pb.TagNumber(1)
  set manualId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasManualId() => $_has(0);
  @$pb.TagNumber(1)
  void clearManualId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$0.PlatformTarget> get proposed => $_getList(1);
}

enum ChangePlatformTargetsResponse_Result { manual, error, notSet }

class ChangePlatformTargetsResponse extends $pb.GeneratedMessage {
  factory ChangePlatformTargetsResponse({
    $0.Manual? manual,
    $1.Error? error,
  }) {
    final result = create();
    if (manual != null) result.manual = manual;
    if (error != null) result.error = error;
    return result;
  }

  ChangePlatformTargetsResponse._();

  factory ChangePlatformTargetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePlatformTargetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangePlatformTargetsResponse_Result>
      _ChangePlatformTargetsResponse_ResultByTag = {
    1: ChangePlatformTargetsResponse_Result.manual,
    2: ChangePlatformTargetsResponse_Result.error,
    0: ChangePlatformTargetsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePlatformTargetsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Manual>(1, _omitFieldNames ? '' : 'manual',
        subBuilder: $0.Manual.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePlatformTargetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePlatformTargetsResponse copyWith(
          void Function(ChangePlatformTargetsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ChangePlatformTargetsResponse))
          as ChangePlatformTargetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePlatformTargetsResponse create() =>
      ChangePlatformTargetsResponse._();
  @$core.override
  ChangePlatformTargetsResponse createEmptyInstance() => create();
  static $pb.PbList<ChangePlatformTargetsResponse> createRepeated() =>
      $pb.PbList<ChangePlatformTargetsResponse>();
  @$core.pragma('dart2js:noInline')
  static ChangePlatformTargetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePlatformTargetsResponse>(create);
  static ChangePlatformTargetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ChangePlatformTargetsResponse_Result whichResult() =>
      _ChangePlatformTargetsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Manual get manual => $_getN(0);
  @$pb.TagNumber(1)
  set manual($0.Manual value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasManual() => $_has(0);
  @$pb.TagNumber(1)
  void clearManual() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Manual ensureManual() => $_ensure(0);

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

class ChangeModulesRequest extends $pb.GeneratedMessage {
  factory ChangeModulesRequest({
    $core.String? manualId,
    $core.Iterable<$0.ManualModuleReference>? proposed,
  }) {
    final result = create();
    if (manualId != null) result.manualId = manualId;
    if (proposed != null) result.proposed.addAll(proposed);
    return result;
  }

  ChangeModulesRequest._();

  factory ChangeModulesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeModulesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeModulesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'manualId')
    ..pPM<$0.ManualModuleReference>(2, _omitFieldNames ? '' : 'proposed',
        subBuilder: $0.ManualModuleReference.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModulesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModulesRequest copyWith(void Function(ChangeModulesRequest) updates) =>
      super.copyWith((message) => updates(message as ChangeModulesRequest))
          as ChangeModulesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeModulesRequest create() => ChangeModulesRequest._();
  @$core.override
  ChangeModulesRequest createEmptyInstance() => create();
  static $pb.PbList<ChangeModulesRequest> createRepeated() =>
      $pb.PbList<ChangeModulesRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangeModulesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeModulesRequest>(create);
  static ChangeModulesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get manualId => $_getSZ(0);
  @$pb.TagNumber(1)
  set manualId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasManualId() => $_has(0);
  @$pb.TagNumber(1)
  void clearManualId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$0.ManualModuleReference> get proposed => $_getList(1);
}

enum ChangeModulesResponse_Result { manual, error, notSet }

class ChangeModulesResponse extends $pb.GeneratedMessage {
  factory ChangeModulesResponse({
    $0.Manual? manual,
    $1.Error? error,
  }) {
    final result = create();
    if (manual != null) result.manual = manual;
    if (error != null) result.error = error;
    return result;
  }

  ChangeModulesResponse._();

  factory ChangeModulesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeModulesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangeModulesResponse_Result>
      _ChangeModulesResponse_ResultByTag = {
    1: ChangeModulesResponse_Result.manual,
    2: ChangeModulesResponse_Result.error,
    0: ChangeModulesResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeModulesResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Manual>(1, _omitFieldNames ? '' : 'manual',
        subBuilder: $0.Manual.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModulesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModulesResponse copyWith(
          void Function(ChangeModulesResponse) updates) =>
      super.copyWith((message) => updates(message as ChangeModulesResponse))
          as ChangeModulesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeModulesResponse create() => ChangeModulesResponse._();
  @$core.override
  ChangeModulesResponse createEmptyInstance() => create();
  static $pb.PbList<ChangeModulesResponse> createRepeated() =>
      $pb.PbList<ChangeModulesResponse>();
  @$core.pragma('dart2js:noInline')
  static ChangeModulesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeModulesResponse>(create);
  static ChangeModulesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ChangeModulesResponse_Result whichResult() =>
      _ChangeModulesResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Manual get manual => $_getN(0);
  @$pb.TagNumber(1)
  set manual($0.Manual value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasManual() => $_has(0);
  @$pb.TagNumber(1)
  void clearManual() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Manual ensureManual() => $_ensure(0);

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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
