// This is a generated file - do not edit.
//
// Generated from api/book.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/book.pb.dart' as $0;
import '../models/common.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListBooksRequest extends $pb.GeneratedMessage {
  factory ListBooksRequest() => create();

  ListBooksRequest._();

  factory ListBooksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBooksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBooksRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBooksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBooksRequest copyWith(void Function(ListBooksRequest) updates) =>
      super.copyWith((message) => updates(message as ListBooksRequest))
          as ListBooksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBooksRequest create() => ListBooksRequest._();
  @$core.override
  ListBooksRequest createEmptyInstance() => create();
  static $pb.PbList<ListBooksRequest> createRepeated() =>
      $pb.PbList<ListBooksRequest>();
  @$core.pragma('dart2js:noInline')
  static ListBooksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBooksRequest>(create);
  static ListBooksRequest? _defaultInstance;
}

class ListBooksResponse extends $pb.GeneratedMessage {
  factory ListBooksResponse({
    $core.Iterable<$0.Book>? books,
  }) {
    final result = create();
    if (books != null) result.books.addAll(books);
    return result;
  }

  ListBooksResponse._();

  factory ListBooksResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBooksResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBooksResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$0.Book>(1, _omitFieldNames ? '' : 'books',
        subBuilder: $0.Book.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBooksResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBooksResponse copyWith(void Function(ListBooksResponse) updates) =>
      super.copyWith((message) => updates(message as ListBooksResponse))
          as ListBooksResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBooksResponse create() => ListBooksResponse._();
  @$core.override
  ListBooksResponse createEmptyInstance() => create();
  static $pb.PbList<ListBooksResponse> createRepeated() =>
      $pb.PbList<ListBooksResponse>();
  @$core.pragma('dart2js:noInline')
  static ListBooksResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBooksResponse>(create);
  static ListBooksResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Book> get books => $_getList(0);
}

class GetBookRequest extends $pb.GeneratedMessage {
  factory GetBookRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetBookRequest._();

  factory GetBookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBookRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookRequest copyWith(void Function(GetBookRequest) updates) =>
      super.copyWith((message) => updates(message as GetBookRequest))
          as GetBookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBookRequest create() => GetBookRequest._();
  @$core.override
  GetBookRequest createEmptyInstance() => create();
  static $pb.PbList<GetBookRequest> createRepeated() =>
      $pb.PbList<GetBookRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBookRequest>(create);
  static GetBookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

enum GetBookResponse_Result { book, error, notSet }

class GetBookResponse extends $pb.GeneratedMessage {
  factory GetBookResponse({
    $0.Book? book,
    $1.Error? error,
  }) {
    final result = create();
    if (book != null) result.book = book;
    if (error != null) result.error = error;
    return result;
  }

  GetBookResponse._();

  factory GetBookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetBookResponse_Result>
      _GetBookResponse_ResultByTag = {
    1: GetBookResponse_Result.book,
    2: GetBookResponse_Result.error,
    0: GetBookResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBookResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Book>(1, _omitFieldNames ? '' : 'book', subBuilder: $0.Book.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookResponse copyWith(void Function(GetBookResponse) updates) =>
      super.copyWith((message) => updates(message as GetBookResponse))
          as GetBookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBookResponse create() => GetBookResponse._();
  @$core.override
  GetBookResponse createEmptyInstance() => create();
  static $pb.PbList<GetBookResponse> createRepeated() =>
      $pb.PbList<GetBookResponse>();
  @$core.pragma('dart2js:noInline')
  static GetBookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBookResponse>(create);
  static GetBookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetBookResponse_Result whichResult() =>
      _GetBookResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Book get book => $_getN(0);
  @$pb.TagNumber(1)
  set book($0.Book value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBook() => $_has(0);
  @$pb.TagNumber(1)
  void clearBook() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Book ensureBook() => $_ensure(0);

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

class UpdateBookRequest extends $pb.GeneratedMessage {
  factory UpdateBookRequest({
    $0.Book? book,
  }) {
    final result = create();
    if (book != null) result.book = book;
    return result;
  }

  UpdateBookRequest._();

  factory UpdateBookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateBookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateBookRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOM<$0.Book>(1, _omitFieldNames ? '' : 'book', subBuilder: $0.Book.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateBookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateBookRequest copyWith(void Function(UpdateBookRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateBookRequest))
          as UpdateBookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateBookRequest create() => UpdateBookRequest._();
  @$core.override
  UpdateBookRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateBookRequest> createRepeated() =>
      $pb.PbList<UpdateBookRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateBookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateBookRequest>(create);
  static UpdateBookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Book get book => $_getN(0);
  @$pb.TagNumber(1)
  set book($0.Book value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBook() => $_has(0);
  @$pb.TagNumber(1)
  void clearBook() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Book ensureBook() => $_ensure(0);
}

enum UpdateBookResponse_Result { book, error, notSet }

class UpdateBookResponse extends $pb.GeneratedMessage {
  factory UpdateBookResponse({
    $0.Book? book,
    $1.Error? error,
  }) {
    final result = create();
    if (book != null) result.book = book;
    if (error != null) result.error = error;
    return result;
  }

  UpdateBookResponse._();

  factory UpdateBookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateBookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateBookResponse_Result>
      _UpdateBookResponse_ResultByTag = {
    1: UpdateBookResponse_Result.book,
    2: UpdateBookResponse_Result.error,
    0: UpdateBookResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateBookResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Book>(1, _omitFieldNames ? '' : 'book', subBuilder: $0.Book.create)
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateBookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateBookResponse copyWith(void Function(UpdateBookResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateBookResponse))
          as UpdateBookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateBookResponse create() => UpdateBookResponse._();
  @$core.override
  UpdateBookResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateBookResponse> createRepeated() =>
      $pb.PbList<UpdateBookResponse>();
  @$core.pragma('dart2js:noInline')
  static UpdateBookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateBookResponse>(create);
  static UpdateBookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UpdateBookResponse_Result whichResult() =>
      _UpdateBookResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Book get book => $_getN(0);
  @$pb.TagNumber(1)
  set book($0.Book value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBook() => $_has(0);
  @$pb.TagNumber(1)
  void clearBook() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Book ensureBook() => $_ensure(0);

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

class CreatePageRequest extends $pb.GeneratedMessage {
  factory CreatePageRequest({
    $core.String? bookId,
    $core.String? name,
    $0.PageType? type,
    $core.String? chapter,
    $core.int? priority,
  }) {
    final result = create();
    if (bookId != null) result.bookId = bookId;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (chapter != null) result.chapter = chapter;
    if (priority != null) result.priority = priority;
    return result;
  }

  CreatePageRequest._();

  factory CreatePageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreatePageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'bookId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<$0.PageType>(3, _omitFieldNames ? '' : 'type',
        enumValues: $0.PageType.values)
    ..aOS(4, _omitFieldNames ? '' : 'chapter')
    ..aI(5, _omitFieldNames ? '' : 'priority')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePageRequest copyWith(void Function(CreatePageRequest) updates) =>
      super.copyWith((message) => updates(message as CreatePageRequest))
          as CreatePageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreatePageRequest create() => CreatePageRequest._();
  @$core.override
  CreatePageRequest createEmptyInstance() => create();
  static $pb.PbList<CreatePageRequest> createRepeated() =>
      $pb.PbList<CreatePageRequest>();
  @$core.pragma('dart2js:noInline')
  static CreatePageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePageRequest>(create);
  static CreatePageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set bookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBookId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.PageType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type($0.PageType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get chapter => $_getSZ(3);
  @$pb.TagNumber(4)
  set chapter($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChapter() => $_has(3);
  @$pb.TagNumber(4)
  void clearChapter() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get priority => $_getIZ(4);
  @$pb.TagNumber(5)
  set priority($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => $_clearField(5);
}

enum CreatePageResponse_Result { pageId, error, notSet }

class CreatePageResponse extends $pb.GeneratedMessage {
  factory CreatePageResponse({
    $core.String? pageId,
    $1.Error? error,
  }) {
    final result = create();
    if (pageId != null) result.pageId = pageId;
    if (error != null) result.error = error;
    return result;
  }

  CreatePageResponse._();

  factory CreatePageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreatePageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CreatePageResponse_Result>
      _CreatePageResponse_ResultByTag = {
    1: CreatePageResponse_Result.pageId,
    2: CreatePageResponse_Result.error,
    0: CreatePageResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePageResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'pageId')
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePageResponse copyWith(void Function(CreatePageResponse) updates) =>
      super.copyWith((message) => updates(message as CreatePageResponse))
          as CreatePageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreatePageResponse create() => CreatePageResponse._();
  @$core.override
  CreatePageResponse createEmptyInstance() => create();
  static $pb.PbList<CreatePageResponse> createRepeated() =>
      $pb.PbList<CreatePageResponse>();
  @$core.pragma('dart2js:noInline')
  static CreatePageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePageResponse>(create);
  static CreatePageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CreatePageResponse_Result whichResult() =>
      _CreatePageResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get pageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageId() => $_clearField(1);

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

class DeletePageRequest extends $pb.GeneratedMessage {
  factory DeletePageRequest({
    $core.String? pageId,
  }) {
    final result = create();
    if (pageId != null) result.pageId = pageId;
    return result;
  }

  DeletePageRequest._();

  factory DeletePageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePageRequest copyWith(void Function(DeletePageRequest) updates) =>
      super.copyWith((message) => updates(message as DeletePageRequest))
          as DeletePageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePageRequest create() => DeletePageRequest._();
  @$core.override
  DeletePageRequest createEmptyInstance() => create();
  static $pb.PbList<DeletePageRequest> createRepeated() =>
      $pb.PbList<DeletePageRequest>();
  @$core.pragma('dart2js:noInline')
  static DeletePageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePageRequest>(create);
  static DeletePageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageId() => $_clearField(1);
}

enum DeletePageResponse_Result { success, error, notSet }

class DeletePageResponse extends $pb.GeneratedMessage {
  factory DeletePageResponse({
    $core.bool? success,
    $1.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeletePageResponse._();

  factory DeletePageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeletePageResponse_Result>
      _DeletePageResponse_ResultByTag = {
    1: DeletePageResponse_Result.success,
    2: DeletePageResponse_Result.error,
    0: DeletePageResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePageResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePageResponse copyWith(void Function(DeletePageResponse) updates) =>
      super.copyWith((message) => updates(message as DeletePageResponse))
          as DeletePageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePageResponse create() => DeletePageResponse._();
  @$core.override
  DeletePageResponse createEmptyInstance() => create();
  static $pb.PbList<DeletePageResponse> createRepeated() =>
      $pb.PbList<DeletePageResponse>();
  @$core.pragma('dart2js:noInline')
  static DeletePageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePageResponse>(create);
  static DeletePageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeletePageResponse_Result whichResult() =>
      _DeletePageResponse_ResultByTag[$_whichOneof(0)]!;
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

class ChangePagesChaptersRequest extends $pb.GeneratedMessage {
  factory ChangePagesChaptersRequest({
    $core.String? bookId,
    $core.String? oldChapter,
    $core.String? newChapter,
  }) {
    final result = create();
    if (bookId != null) result.bookId = bookId;
    if (oldChapter != null) result.oldChapter = oldChapter;
    if (newChapter != null) result.newChapter = newChapter;
    return result;
  }

  ChangePagesChaptersRequest._();

  factory ChangePagesChaptersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePagesChaptersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePagesChaptersRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'bookId')
    ..aOS(2, _omitFieldNames ? '' : 'oldChapter')
    ..aOS(3, _omitFieldNames ? '' : 'newChapter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePagesChaptersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePagesChaptersRequest copyWith(
          void Function(ChangePagesChaptersRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ChangePagesChaptersRequest))
          as ChangePagesChaptersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePagesChaptersRequest create() => ChangePagesChaptersRequest._();
  @$core.override
  ChangePagesChaptersRequest createEmptyInstance() => create();
  static $pb.PbList<ChangePagesChaptersRequest> createRepeated() =>
      $pb.PbList<ChangePagesChaptersRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangePagesChaptersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePagesChaptersRequest>(create);
  static ChangePagesChaptersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set bookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBookId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get oldChapter => $_getSZ(1);
  @$pb.TagNumber(2)
  set oldChapter($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOldChapter() => $_has(1);
  @$pb.TagNumber(2)
  void clearOldChapter() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get newChapter => $_getSZ(2);
  @$pb.TagNumber(3)
  set newChapter($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNewChapter() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewChapter() => $_clearField(3);
}

enum ChangePagesChaptersResponse_Result { success, error, notSet }

class ChangePagesChaptersResponse extends $pb.GeneratedMessage {
  factory ChangePagesChaptersResponse({
    $core.bool? success,
    $1.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ChangePagesChaptersResponse._();

  factory ChangePagesChaptersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePagesChaptersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangePagesChaptersResponse_Result>
      _ChangePagesChaptersResponse_ResultByTag = {
    1: ChangePagesChaptersResponse_Result.success,
    2: ChangePagesChaptersResponse_Result.error,
    0: ChangePagesChaptersResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePagesChaptersResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$1.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePagesChaptersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePagesChaptersResponse copyWith(
          void Function(ChangePagesChaptersResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ChangePagesChaptersResponse))
          as ChangePagesChaptersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePagesChaptersResponse create() =>
      ChangePagesChaptersResponse._();
  @$core.override
  ChangePagesChaptersResponse createEmptyInstance() => create();
  static $pb.PbList<ChangePagesChaptersResponse> createRepeated() =>
      $pb.PbList<ChangePagesChaptersResponse>();
  @$core.pragma('dart2js:noInline')
  static ChangePagesChaptersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePagesChaptersResponse>(create);
  static ChangePagesChaptersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ChangePagesChaptersResponse_Result whichResult() =>
      _ChangePagesChaptersResponse_ResultByTag[$_whichOneof(0)]!;
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
