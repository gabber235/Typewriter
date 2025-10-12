// This is a generated file - do not edit.
//
// Generated from api/module.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/common.pb.dart' as $1;
import '../models/module.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListModulesRequest extends $pb.GeneratedMessage {
  factory ListModulesRequest() => create();

  ListModulesRequest._();

  factory ListModulesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListModulesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModulesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModulesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModulesRequest copyWith(void Function(ListModulesRequest) updates) =>
      super.copyWith((message) => updates(message as ListModulesRequest))
          as ListModulesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListModulesRequest create() => ListModulesRequest._();
  @$core.override
  ListModulesRequest createEmptyInstance() => create();
  static $pb.PbList<ListModulesRequest> createRepeated() =>
      $pb.PbList<ListModulesRequest>();
  @$core.pragma('dart2js:noInline')
  static ListModulesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModulesRequest>(create);
  static ListModulesRequest? _defaultInstance;
}

class ListModulesResponse extends $pb.GeneratedMessage {
  factory ListModulesResponse({
    $core.Iterable<$0.Module>? modules,
  }) {
    final result = create();
    if (modules != null) result.modules.addAll(modules);
    return result;
  }

  ListModulesResponse._();

  factory ListModulesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListModulesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModulesResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Module>(1, _omitFieldNames ? '' : 'modules',
        subBuilder: $0.Module.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModulesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModulesResponse copyWith(void Function(ListModulesResponse) updates) =>
      super.copyWith((message) => updates(message as ListModulesResponse))
          as ListModulesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListModulesResponse create() => ListModulesResponse._();
  @$core.override
  ListModulesResponse createEmptyInstance() => create();
  static $pb.PbList<ListModulesResponse> createRepeated() =>
      $pb.PbList<ListModulesResponse>();
  @$core.pragma('dart2js:noInline')
  static ListModulesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModulesResponse>(create);
  static ListModulesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Module> get modules => $_getList(0);
}

class GetModuleRequest extends $pb.GeneratedMessage {
  factory GetModuleRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetModuleRequest._();

  factory GetModuleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModuleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModuleRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModuleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModuleRequest copyWith(void Function(GetModuleRequest) updates) =>
      super.copyWith((message) => updates(message as GetModuleRequest))
          as GetModuleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModuleRequest create() => GetModuleRequest._();
  @$core.override
  GetModuleRequest createEmptyInstance() => create();
  static $pb.PbList<GetModuleRequest> createRepeated() =>
      $pb.PbList<GetModuleRequest>();
  @$core.pragma('dart2js:noInline')
  static GetModuleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModuleRequest>(create);
  static GetModuleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum GetModuleResponse_Result { module, error, notSet }

class GetModuleResponse extends $pb.GeneratedMessage {
  factory GetModuleResponse({
    $0.Module? module,
    $1.Error? error,
  }) {
    final result = create();
    if (module != null) result.module = module;
    if (error != null) result.error = error;
    return result;
  }

  GetModuleResponse._();

  factory GetModuleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModuleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetModuleResponse_Result>
      _GetModuleResponse_ResultByTag = {
    1: GetModuleResponse_Result.module,
    2: GetModuleResponse_Result.error,
    0: GetModuleResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModuleResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Module>(1, _omitFieldNames ? '' : 'module',
        subBuilder: $0.Module.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModuleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModuleResponse copyWith(void Function(GetModuleResponse) updates) =>
      super.copyWith((message) => updates(message as GetModuleResponse))
          as GetModuleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModuleResponse create() => GetModuleResponse._();
  @$core.override
  GetModuleResponse createEmptyInstance() => create();
  static $pb.PbList<GetModuleResponse> createRepeated() =>
      $pb.PbList<GetModuleResponse>();
  @$core.pragma('dart2js:noInline')
  static GetModuleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModuleResponse>(create);
  static GetModuleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetModuleResponse_Result whichResult() =>
      _GetModuleResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Module get module => $_getN(0);
  @$pb.TagNumber(1)
  set module($0.Module value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModule() => $_has(0);
  @$pb.TagNumber(1)
  void clearModule() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Module ensureModule() => $_ensure(0);

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

class UpdateModuleRequest extends $pb.GeneratedMessage {
  factory UpdateModuleRequest({
    $0.Module? module,
  }) {
    final result = create();
    if (module != null) result.module = module;
    return result;
  }

  UpdateModuleRequest._();

  factory UpdateModuleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateModuleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateModuleRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOM<$0.Module>(1, _omitFieldNames ? '' : 'module',
        subBuilder: $0.Module.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateModuleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateModuleRequest copyWith(void Function(UpdateModuleRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateModuleRequest))
          as UpdateModuleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateModuleRequest create() => UpdateModuleRequest._();
  @$core.override
  UpdateModuleRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateModuleRequest> createRepeated() =>
      $pb.PbList<UpdateModuleRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateModuleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateModuleRequest>(create);
  static UpdateModuleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Module get module => $_getN(0);
  @$pb.TagNumber(1)
  set module($0.Module value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModule() => $_has(0);
  @$pb.TagNumber(1)
  void clearModule() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Module ensureModule() => $_ensure(0);
}

enum UpdateModuleResponse_Result { module, error, notSet }

class UpdateModuleResponse extends $pb.GeneratedMessage {
  factory UpdateModuleResponse({
    $0.Module? module,
    $1.Error? error,
  }) {
    final result = create();
    if (module != null) result.module = module;
    if (error != null) result.error = error;
    return result;
  }

  UpdateModuleResponse._();

  factory UpdateModuleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateModuleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateModuleResponse_Result>
      _UpdateModuleResponse_ResultByTag = {
    1: UpdateModuleResponse_Result.module,
    2: UpdateModuleResponse_Result.error,
    0: UpdateModuleResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateModuleResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Module>(1, _omitFieldNames ? '' : 'module',
        subBuilder: $0.Module.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateModuleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateModuleResponse copyWith(void Function(UpdateModuleResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateModuleResponse))
          as UpdateModuleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateModuleResponse create() => UpdateModuleResponse._();
  @$core.override
  UpdateModuleResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateModuleResponse> createRepeated() =>
      $pb.PbList<UpdateModuleResponse>();
  @$core.pragma('dart2js:noInline')
  static UpdateModuleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateModuleResponse>(create);
  static UpdateModuleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UpdateModuleResponse_Result whichResult() =>
      _UpdateModuleResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Module get module => $_getN(0);
  @$pb.TagNumber(1)
  set module($0.Module value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModule() => $_has(0);
  @$pb.TagNumber(1)
  void clearModule() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Module ensureModule() => $_ensure(0);

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

class ChangeVersionStateRequest extends $pb.GeneratedMessage {
  factory ChangeVersionStateRequest({
    $core.Iterable<$core.String>? moduleIds,
    $core.String? version,
    $0.ModuleVersionState? state,
  }) {
    final result = create();
    if (moduleIds != null) result.moduleIds.addAll(moduleIds);
    if (version != null) result.version = version;
    if (state != null) result.state = state;
    return result;
  }

  ChangeVersionStateRequest._();

  factory ChangeVersionStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeVersionStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeVersionStateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'moduleIds')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aE<$0.ModuleVersionState>(3, _omitFieldNames ? '' : 'state',
        enumValues: $0.ModuleVersionState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeVersionStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeVersionStateRequest copyWith(
          void Function(ChangeVersionStateRequest) updates) =>
      super.copyWith((message) => updates(message as ChangeVersionStateRequest))
          as ChangeVersionStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeVersionStateRequest create() => ChangeVersionStateRequest._();
  @$core.override
  ChangeVersionStateRequest createEmptyInstance() => create();
  static $pb.PbList<ChangeVersionStateRequest> createRepeated() =>
      $pb.PbList<ChangeVersionStateRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangeVersionStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeVersionStateRequest>(create);
  static ChangeVersionStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get moduleIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.ModuleVersionState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state($0.ModuleVersionState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);
}

enum ChangeVersionStateResponse_Result { success, error, notSet }

class ChangeVersionStateResponse extends $pb.GeneratedMessage {
  factory ChangeVersionStateResponse({
    $core.bool? success,
    $1.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ChangeVersionStateResponse._();

  factory ChangeVersionStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeVersionStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangeVersionStateResponse_Result>
      _ChangeVersionStateResponse_ResultByTag = {
    1: ChangeVersionStateResponse_Result.success,
    2: ChangeVersionStateResponse_Result.error,
    0: ChangeVersionStateResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeVersionStateResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeVersionStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeVersionStateResponse copyWith(
          void Function(ChangeVersionStateResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ChangeVersionStateResponse))
          as ChangeVersionStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeVersionStateResponse create() => ChangeVersionStateResponse._();
  @$core.override
  ChangeVersionStateResponse createEmptyInstance() => create();
  static $pb.PbList<ChangeVersionStateResponse> createRepeated() =>
      $pb.PbList<ChangeVersionStateResponse>();
  @$core.pragma('dart2js:noInline')
  static ChangeVersionStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeVersionStateResponse>(create);
  static ChangeVersionStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ChangeVersionStateResponse_Result whichResult() =>
      _ChangeVersionStateResponse_ResultByTag[$_whichOneof(0)]!;
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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
