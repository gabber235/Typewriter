// This is a generated file - do not edit.
//
// Generated from api/page.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use searchPagesRequestDescriptor instead')
const SearchPagesRequest$json = {
  '1': 'SearchPagesRequest',
  '2': [
    {'1': 'book_id', '3': 1, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'search', '3': 2, '4': 1, '5': 9, '10': 'search'},
  ],
};

/// Descriptor for `SearchPagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchPagesRequestDescriptor = $convert.base64Decode(
    'ChJTZWFyY2hQYWdlc1JlcXVlc3QSFwoHYm9va19pZBgBIAEoCVIGYm9va0lkEhYKBnNlYXJjaB'
    'gCIAEoCVIGc2VhcmNo');

@$core.Deprecated('Use searchPagesResultDescriptor instead')
const SearchPagesResult$json = {
  '1': 'SearchPagesResult',
  '2': [
    {
      '1': 'pages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Page',
      '10': 'pages'
    },
  ],
};

/// Descriptor for `SearchPagesResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchPagesResultDescriptor = $convert.base64Decode(
    'ChFTZWFyY2hQYWdlc1Jlc3VsdBIwCgVwYWdlcxgBIAMoCzIaLnR5cGV3cml0ZXIubW9kZWxzLn'
    'YxLlBhZ2VSBXBhZ2Vz');

@$core.Deprecated('Use searchPagesResponseDescriptor instead')
const SearchPagesResponse$json = {
  '1': 'SearchPagesResponse',
  '2': [
    {
      '1': 'pages',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.SearchPagesResult',
      '9': 0,
      '10': 'pages'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `SearchPagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchPagesResponseDescriptor = $convert.base64Decode(
    'ChNTZWFyY2hQYWdlc1Jlc3BvbnNlEjwKBXBhZ2VzGAEgASgLMiQudHlwZXdyaXRlci5hcGkudj'
    'EuU2VhcmNoUGFnZXNSZXN1bHRIAFIFcGFnZXMSMwoFZXJyb3IYAiABKAsyGy50eXBld3JpdGVy'
    'Lm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use getPageRequestDescriptor instead')
const GetPageRequest$json = {
  '1': 'GetPageRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetPageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPageRequestDescriptor =
    $convert.base64Decode('Cg5HZXRQYWdlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use getPageResponseDescriptor instead')
const GetPageResponse$json = {
  '1': 'GetPageResponse',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Page',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `GetPageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPageResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRQYWdlUmVzcG9uc2USMAoEcGFnZRgBIAEoCzIaLnR5cGV3cml0ZXIubW9kZWxzLnYxLl'
    'BhZ2VIAFIEcGFnZRIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9y'
    'SABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use updatePageRequestDescriptor instead')
const UpdatePageRequest$json = {
  '1': 'UpdatePageRequest',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Page',
      '10': 'page'
    },
  ],
};

/// Descriptor for `UpdatePageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePageRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVQYWdlUmVxdWVzdBIuCgRwYWdlGAEgASgLMhoudHlwZXdyaXRlci5tb2RlbHMudj'
    'EuUGFnZVIEcGFnZQ==');

@$core.Deprecated('Use updatePageResponseDescriptor instead')
const UpdatePageResponse$json = {
  '1': 'UpdatePageResponse',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Page',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `UpdatePageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePageResponseDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVQYWdlUmVzcG9uc2USMAoEcGFnZRgBIAEoCzIaLnR5cGV3cml0ZXIubW9kZWxzLn'
    'YxLlBhZ2VIAFIEcGFnZRIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVy'
    'cm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use changePageChapterRequestDescriptor instead')
const ChangePageChapterRequest$json = {
  '1': 'ChangePageChapterRequest',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'chapter', '3': 2, '4': 1, '5': 9, '10': 'chapter'},
  ],
};

/// Descriptor for `ChangePageChapterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePageChapterRequestDescriptor =
    $convert.base64Decode(
        'ChhDaGFuZ2VQYWdlQ2hhcHRlclJlcXVlc3QSFwoHcGFnZV9pZBgBIAEoCVIGcGFnZUlkEhgKB2'
        'NoYXB0ZXIYAiABKAlSB2NoYXB0ZXI=');

@$core.Deprecated('Use changePageChapterResponseDescriptor instead')
const ChangePageChapterResponse$json = {
  '1': 'ChangePageChapterResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ChangePageChapterResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePageChapterResponseDescriptor = $convert.base64Decode(
    'ChlDaGFuZ2VQYWdlQ2hhcHRlclJlc3BvbnNlEhoKB3N1Y2Nlc3MYASABKAhIAFIHc3VjY2Vzcx'
    'IzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggK'
    'BnJlc3VsdA==');

@$core.Deprecated('Use changePagePriorityRequestDescriptor instead')
const ChangePagePriorityRequest$json = {
  '1': 'ChangePagePriorityRequest',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'priority', '3': 2, '4': 1, '5': 5, '10': 'priority'},
  ],
};

/// Descriptor for `ChangePagePriorityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePagePriorityRequestDescriptor =
    $convert.base64Decode(
        'ChlDaGFuZ2VQYWdlUHJpb3JpdHlSZXF1ZXN0EhcKB3BhZ2VfaWQYASABKAlSBnBhZ2VJZBIaCg'
        'hwcmlvcml0eRgCIAEoBVIIcHJpb3JpdHk=');

@$core.Deprecated('Use changePagePriorityResponseDescriptor instead')
const ChangePagePriorityResponse$json = {
  '1': 'ChangePagePriorityResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ChangePagePriorityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePagePriorityResponseDescriptor =
    $convert.base64Decode(
        'ChpDaGFuZ2VQYWdlUHJpb3JpdHlSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3'
        'MSMwoFZXJyb3IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckII'
        'CgZyZXN1bHQ=');

@$core.Deprecated('Use renamePageRequestDescriptor instead')
const RenamePageRequest$json = {
  '1': 'RenamePageRequest',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `RenamePageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renamePageRequestDescriptor = $convert.base64Decode(
    'ChFSZW5hbWVQYWdlUmVxdWVzdBIXCgdwYWdlX2lkGAEgASgJUgZwYWdlSWQSEgoEbmFtZRgCIA'
    'EoCVIEbmFtZQ==');

@$core.Deprecated('Use renamePageResponseDescriptor instead')
const RenamePageResponse$json = {
  '1': 'RenamePageResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `RenamePageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renamePageResponseDescriptor = $convert.base64Decode(
    'ChJSZW5hbWVQYWdlUmVzcG9uc2USGgoHc3VjY2VzcxgBIAEoCEgAUgdzdWNjZXNzEjMKBWVycm'
    '9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');
