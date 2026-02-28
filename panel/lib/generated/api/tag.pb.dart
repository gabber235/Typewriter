// This is a generated file - do not edit.
//
// Generated from api/tag.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/book.pb.dart' as $1;
import '../models/common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListTagsRequest extends $pb.GeneratedMessage {
  factory ListTagsRequest() => create();

  ListTagsRequest._();

  factory ListTagsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTagsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTagsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTagsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTagsRequest copyWith(void Function(ListTagsRequest) updates) =>
      super.copyWith((message) => updates(message as ListTagsRequest))
          as ListTagsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTagsRequest create() => ListTagsRequest._();
  @$core.override
  ListTagsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTagsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTagsRequest>(create);
  static ListTagsRequest? _defaultInstance;
}

enum ListTagsResponse_Result { tags, error, notSet }

class ListTagsResponse extends $pb.GeneratedMessage {
  factory ListTagsResponse({
    ListTags? tags,
    $0.Error? error,
  }) {
    final result = create();
    if (tags != null) result.tags = tags;
    if (error != null) result.error = error;
    return result;
  }

  ListTagsResponse._();

  factory ListTagsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTagsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListTagsResponse_Result>
      _ListTagsResponse_ResultByTag = {
    1: ListTagsResponse_Result.tags,
    2: ListTagsResponse_Result.error,
    0: ListTagsResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTagsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ListTags>(1, _omitFieldNames ? '' : 'tags',
        subBuilder: ListTags.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTagsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTagsResponse copyWith(void Function(ListTagsResponse) updates) =>
      super.copyWith((message) => updates(message as ListTagsResponse))
          as ListTagsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTagsResponse create() => ListTagsResponse._();
  @$core.override
  ListTagsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTagsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTagsResponse>(create);
  static ListTagsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListTagsResponse_Result whichResult() =>
      _ListTagsResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ListTags get tags => $_getN(0);
  @$pb.TagNumber(1)
  set tags(ListTags value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTags() => $_has(0);
  @$pb.TagNumber(1)
  void clearTags() => $_clearField(1);
  @$pb.TagNumber(1)
  ListTags ensureTags() => $_ensure(0);

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

class ListTags extends $pb.GeneratedMessage {
  factory ListTags({
    $core.Iterable<$1.Tag>? tags,
  }) {
    final result = create();
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  ListTags._();

  factory ListTags.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTags.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTags',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.Tag>(1, _omitFieldNames ? '' : 'tags', subBuilder: $1.Tag.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTags clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTags copyWith(void Function(ListTags) updates) =>
      super.copyWith((message) => updates(message as ListTags)) as ListTags;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTags create() => ListTags._();
  @$core.override
  ListTags createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTags getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListTags>(create);
  static ListTags? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.Tag> get tags => $_getList(0);
}

class GetTagRequest extends $pb.GeneratedMessage {
  factory GetTagRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetTagRequest._();

  factory GetTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTagRequest copyWith(void Function(GetTagRequest) updates) =>
      super.copyWith((message) => updates(message as GetTagRequest))
          as GetTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTagRequest create() => GetTagRequest._();
  @$core.override
  GetTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTagRequest>(create);
  static GetTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum GetTagResponse_Result { tag, error, notSet }

class GetTagResponse extends $pb.GeneratedMessage {
  factory GetTagResponse({
    $1.Tag? tag,
    $0.Error? error,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    if (error != null) result.error = error;
    return result;
  }

  GetTagResponse._();

  factory GetTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetTagResponse_Result>
      _GetTagResponse_ResultByTag = {
    1: GetTagResponse_Result.tag,
    2: GetTagResponse_Result.error,
    0: GetTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.Tag>(1, _omitFieldNames ? '' : 'tag', subBuilder: $1.Tag.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTagResponse copyWith(void Function(GetTagResponse) updates) =>
      super.copyWith((message) => updates(message as GetTagResponse))
          as GetTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTagResponse create() => GetTagResponse._();
  @$core.override
  GetTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTagResponse>(create);
  static GetTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetTagResponse_Result whichResult() =>
      _GetTagResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.Tag get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag($1.Tag value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Tag ensureTag() => $_ensure(0);

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

class CreateTagRequest extends $pb.GeneratedMessage {
  factory CreateTagRequest({
    $core.String? name,
    $0.Color? color,
    $core.Iterable<$core.String>? parentIds,
    $1.Placement? placement,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (color != null) result.color = color;
    if (parentIds != null) result.parentIds.addAll(parentIds);
    if (placement != null) result.placement = placement;
    return result;
  }

  CreateTagRequest._();

  factory CreateTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Color>(2, _omitFieldNames ? '' : 'color',
        subBuilder: $0.Color.create)
    ..pPS(3, _omitFieldNames ? '' : 'parentIds')
    ..aOM<$1.Placement>(4, _omitFieldNames ? '' : 'placement',
        subBuilder: $1.Placement.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTagRequest copyWith(void Function(CreateTagRequest) updates) =>
      super.copyWith((message) => updates(message as CreateTagRequest))
          as CreateTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateTagRequest create() => CreateTagRequest._();
  @$core.override
  CreateTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateTagRequest>(create);
  static CreateTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Color get color => $_getN(1);
  @$pb.TagNumber(2)
  set color($0.Color value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Color ensureColor() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get parentIds => $_getList(2);

  @$pb.TagNumber(4)
  $1.Placement get placement => $_getN(3);
  @$pb.TagNumber(4)
  set placement($1.Placement value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPlacement() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlacement() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Placement ensurePlacement() => $_ensure(3);
}

enum CreateTagResponse_Result { tag, error, notSet }

class CreateTagResponse extends $pb.GeneratedMessage {
  factory CreateTagResponse({
    $1.Tag? tag,
    $0.Error? error,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    if (error != null) result.error = error;
    return result;
  }

  CreateTagResponse._();

  factory CreateTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CreateTagResponse_Result>
      _CreateTagResponse_ResultByTag = {
    1: CreateTagResponse_Result.tag,
    2: CreateTagResponse_Result.error,
    0: CreateTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.Tag>(1, _omitFieldNames ? '' : 'tag', subBuilder: $1.Tag.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTagResponse copyWith(void Function(CreateTagResponse) updates) =>
      super.copyWith((message) => updates(message as CreateTagResponse))
          as CreateTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateTagResponse create() => CreateTagResponse._();
  @$core.override
  CreateTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateTagResponse>(create);
  static CreateTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CreateTagResponse_Result whichResult() =>
      _CreateTagResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.Tag get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag($1.Tag value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Tag ensureTag() => $_ensure(0);

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

class UpdateTagRequest extends $pb.GeneratedMessage {
  factory UpdateTagRequest({
    $1.Tag? tag,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    return result;
  }

  UpdateTagRequest._();

  factory UpdateTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Tag>(1, _omitFieldNames ? '' : 'tag', subBuilder: $1.Tag.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagRequest copyWith(void Function(UpdateTagRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateTagRequest))
          as UpdateTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateTagRequest create() => UpdateTagRequest._();
  @$core.override
  UpdateTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateTagRequest>(create);
  static UpdateTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Tag get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag($1.Tag value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Tag ensureTag() => $_ensure(0);
}

enum UpdateTagResponse_Result { tag, error, notSet }

class UpdateTagResponse extends $pb.GeneratedMessage {
  factory UpdateTagResponse({
    $1.Tag? tag,
    $0.Error? error,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    if (error != null) result.error = error;
    return result;
  }

  UpdateTagResponse._();

  factory UpdateTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateTagResponse_Result>
      _UpdateTagResponse_ResultByTag = {
    1: UpdateTagResponse_Result.tag,
    2: UpdateTagResponse_Result.error,
    0: UpdateTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.Tag>(1, _omitFieldNames ? '' : 'tag', subBuilder: $1.Tag.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTagResponse copyWith(void Function(UpdateTagResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateTagResponse))
          as UpdateTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateTagResponse create() => UpdateTagResponse._();
  @$core.override
  UpdateTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateTagResponse>(create);
  static UpdateTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UpdateTagResponse_Result whichResult() =>
      _UpdateTagResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.Tag get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag($1.Tag value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Tag ensureTag() => $_ensure(0);

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

class DeleteTagRequest extends $pb.GeneratedMessage {
  factory DeleteTagRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteTagRequest._();

  factory DeleteTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTagRequest copyWith(void Function(DeleteTagRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteTagRequest))
          as DeleteTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteTagRequest create() => DeleteTagRequest._();
  @$core.override
  DeleteTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteTagRequest>(create);
  static DeleteTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum DeleteTagResponse_Result { success, error, notSet }

class DeleteTagResponse extends $pb.GeneratedMessage {
  factory DeleteTagResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteTagResponse._();

  factory DeleteTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeleteTagResponse_Result>
      _DeleteTagResponse_ResultByTag = {
    1: DeleteTagResponse_Result.success,
    2: DeleteTagResponse_Result.error,
    0: DeleteTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTagResponse copyWith(void Function(DeleteTagResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteTagResponse))
          as DeleteTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteTagResponse create() => DeleteTagResponse._();
  @$core.override
  DeleteTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteTagResponse>(create);
  static DeleteTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeleteTagResponse_Result whichResult() =>
      _DeleteTagResponse_ResultByTag[$_whichOneof(0)]!;
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

class MoveTagRequest extends $pb.GeneratedMessage {
  factory MoveTagRequest({
    $core.String? id,
    $core.int? x,
    $core.int? y,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  MoveTagRequest._();

  factory MoveTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MoveTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'x')
    ..aI(3, _omitFieldNames ? '' : 'y')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveTagRequest copyWith(void Function(MoveTagRequest) updates) =>
      super.copyWith((message) => updates(message as MoveTagRequest))
          as MoveTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MoveTagRequest create() => MoveTagRequest._();
  @$core.override
  MoveTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MoveTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveTagRequest>(create);
  static MoveTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get x => $_getIZ(1);
  @$pb.TagNumber(2)
  set x($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get y => $_getIZ(2);
  @$pb.TagNumber(3)
  set y($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => $_clearField(3);
}

enum MoveTagResponse_Result { success, error, notSet }

class MoveTagResponse extends $pb.GeneratedMessage {
  factory MoveTagResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  MoveTagResponse._();

  factory MoveTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MoveTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MoveTagResponse_Result>
      _MoveTagResponse_ResultByTag = {
    1: MoveTagResponse_Result.success,
    2: MoveTagResponse_Result.error,
    0: MoveTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveTagResponse copyWith(void Function(MoveTagResponse) updates) =>
      super.copyWith((message) => updates(message as MoveTagResponse))
          as MoveTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MoveTagResponse create() => MoveTagResponse._();
  @$core.override
  MoveTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MoveTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveTagResponse>(create);
  static MoveTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  MoveTagResponse_Result whichResult() =>
      _MoveTagResponse_ResultByTag[$_whichOneof(0)]!;
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

class ResizeTagRequest extends $pb.GeneratedMessage {
  factory ResizeTagRequest({
    $core.String? id,
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  ResizeTagRequest._();

  factory ResizeTagRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResizeTagRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResizeTagRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'width')
    ..aI(3, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResizeTagRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResizeTagRequest copyWith(void Function(ResizeTagRequest) updates) =>
      super.copyWith((message) => updates(message as ResizeTagRequest))
          as ResizeTagRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResizeTagRequest create() => ResizeTagRequest._();
  @$core.override
  ResizeTagRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResizeTagRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResizeTagRequest>(create);
  static ResizeTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => $_clearField(3);
}

enum ResizeTagResponse_Result { success, error, notSet }

class ResizeTagResponse extends $pb.GeneratedMessage {
  factory ResizeTagResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ResizeTagResponse._();

  factory ResizeTagResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResizeTagResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ResizeTagResponse_Result>
      _ResizeTagResponse_ResultByTag = {
    1: ResizeTagResponse_Result.success,
    2: ResizeTagResponse_Result.error,
    0: ResizeTagResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResizeTagResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResizeTagResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResizeTagResponse copyWith(void Function(ResizeTagResponse) updates) =>
      super.copyWith((message) => updates(message as ResizeTagResponse))
          as ResizeTagResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResizeTagResponse create() => ResizeTagResponse._();
  @$core.override
  ResizeTagResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResizeTagResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResizeTagResponse>(create);
  static ResizeTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ResizeTagResponse_Result whichResult() =>
      _ResizeTagResponse_ResultByTag[$_whichOneof(0)]!;
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
