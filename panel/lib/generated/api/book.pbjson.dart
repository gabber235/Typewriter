// This is a generated file - do not edit.
//
// Generated from api/book.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use listBooksRequestDescriptor instead')
const ListBooksRequest$json = {
  '1': 'ListBooksRequest',
};

/// Descriptor for `ListBooksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBooksRequestDescriptor =
    $convert.base64Decode('ChBMaXN0Qm9va3NSZXF1ZXN0');

@$core.Deprecated('Use listBooksResponseDescriptor instead')
const ListBooksResponse$json = {
  '1': 'ListBooksResponse',
  '2': [
    {
      '1': 'books',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListBooks',
      '9': 0,
      '10': 'books'
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

/// Descriptor for `ListBooksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBooksResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Qm9va3NSZXNwb25zZRI0CgVib29rcxgBIAEoCzIcLnR5cGV3cml0ZXIuYXBpLnYxLk'
    'xpc3RCb29rc0gAUgVib29rcxIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYx'
    'LkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use listBooksDescriptor instead')
const ListBooks$json = {
  '1': 'ListBooks',
  '2': [
    {
      '1': 'books',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Book',
      '10': 'books'
    },
  ],
};

/// Descriptor for `ListBooks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBooksDescriptor = $convert.base64Decode(
    'CglMaXN0Qm9va3MSMAoFYm9va3MYASADKAsyGi50eXBld3JpdGVyLm1vZGVscy52MS5Cb29rUg'
    'Vib29rcw==');

@$core.Deprecated('Use getBookRequestDescriptor instead')
const GetBookRequest$json = {
  '1': 'GetBookRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetBookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBookRequestDescriptor =
    $convert.base64Decode('Cg5HZXRCb29rUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use getBookResponseDescriptor instead')
const GetBookResponse$json = {
  '1': 'GetBookResponse',
  '2': [
    {
      '1': 'book',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Book',
      '9': 0,
      '10': 'book'
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

/// Descriptor for `GetBookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBookResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRCb29rUmVzcG9uc2USMAoEYm9vaxgBIAEoCzIaLnR5cGV3cml0ZXIubW9kZWxzLnYxLk'
    'Jvb2tIAFIEYm9vaxIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9y'
    'SABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use updateBookRequestDescriptor instead')
const UpdateBookRequest$json = {
  '1': 'UpdateBookRequest',
  '2': [
    {
      '1': 'book',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Book',
      '10': 'book'
    },
  ],
};

/// Descriptor for `UpdateBookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateBookRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVCb29rUmVxdWVzdBIuCgRib29rGAEgASgLMhoudHlwZXdyaXRlci5tb2RlbHMudj'
    'EuQm9va1IEYm9vaw==');

@$core.Deprecated('Use updateBookResponseDescriptor instead')
const UpdateBookResponse$json = {
  '1': 'UpdateBookResponse',
  '2': [
    {
      '1': 'book',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Book',
      '9': 0,
      '10': 'book'
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

/// Descriptor for `UpdateBookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateBookResponseDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVCb29rUmVzcG9uc2USMAoEYm9vaxgBIAEoCzIaLnR5cGV3cml0ZXIubW9kZWxzLn'
    'YxLkJvb2tIAFIEYm9vaxIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVy'
    'cm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use createPageRequestDescriptor instead')
const CreatePageRequest$json = {
  '1': 'CreatePageRequest',
  '2': [
    {'1': 'book_id', '3': 1, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.PageType',
      '10': 'type'
    },
    {'1': 'chapter', '3': 4, '4': 1, '5': 9, '10': 'chapter'},
    {'1': 'priority', '3': 5, '4': 1, '5': 5, '10': 'priority'},
  ],
};

/// Descriptor for `CreatePageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPageRequestDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVQYWdlUmVxdWVzdBIXCgdib29rX2lkGAEgASgJUgZib29rSWQSEgoEbmFtZRgCIA'
    'EoCVIEbmFtZRIyCgR0eXBlGAMgASgOMh4udHlwZXdyaXRlci5tb2RlbHMudjEuUGFnZVR5cGVS'
    'BHR5cGUSGAoHY2hhcHRlchgEIAEoCVIHY2hhcHRlchIaCghwcmlvcml0eRgFIAEoBVIIcHJpb3'
    'JpdHk=');

@$core.Deprecated('Use createPageResponseDescriptor instead')
const CreatePageResponse$json = {
  '1': 'CreatePageResponse',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'pageId'},
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

/// Descriptor for `CreatePageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPageResponseDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVQYWdlUmVzcG9uc2USGQoHcGFnZV9pZBgBIAEoCUgAUgZwYWdlSWQSMwoFZXJyb3'
    'IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use deletePageRequestDescriptor instead')
const DeletePageRequest$json = {
  '1': 'DeletePageRequest',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
  ],
};

/// Descriptor for `DeletePageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePageRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVQYWdlUmVxdWVzdBIXCgdwYWdlX2lkGAEgASgJUgZwYWdlSWQ=');

@$core.Deprecated('Use deletePageResponseDescriptor instead')
const DeletePageResponse$json = {
  '1': 'DeletePageResponse',
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

/// Descriptor for `DeletePageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePageResponseDescriptor = $convert.base64Decode(
    'ChJEZWxldGVQYWdlUmVzcG9uc2USGgoHc3VjY2VzcxgBIAEoCEgAUgdzdWNjZXNzEjMKBWVycm'
    '9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use changePagesChaptersRequestDescriptor instead')
const ChangePagesChaptersRequest$json = {
  '1': 'ChangePagesChaptersRequest',
  '2': [
    {'1': 'book_id', '3': 1, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'old_chapter', '3': 2, '4': 1, '5': 9, '10': 'oldChapter'},
    {'1': 'new_chapter', '3': 3, '4': 1, '5': 9, '10': 'newChapter'},
  ],
};

/// Descriptor for `ChangePagesChaptersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePagesChaptersRequestDescriptor =
    $convert.base64Decode(
        'ChpDaGFuZ2VQYWdlc0NoYXB0ZXJzUmVxdWVzdBIXCgdib29rX2lkGAEgASgJUgZib29rSWQSHw'
        'oLb2xkX2NoYXB0ZXIYAiABKAlSCm9sZENoYXB0ZXISHwoLbmV3X2NoYXB0ZXIYAyABKAlSCm5l'
        'd0NoYXB0ZXI=');

@$core.Deprecated('Use changePagesChaptersResponseDescriptor instead')
const ChangePagesChaptersResponse$json = {
  '1': 'ChangePagesChaptersResponse',
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

/// Descriptor for `ChangePagesChaptersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePagesChaptersResponseDescriptor =
    $convert.base64Decode(
        'ChtDaGFuZ2VQYWdlc0NoYXB0ZXJzUmVzcG9uc2USGgoHc3VjY2VzcxgBIAEoCEgAUgdzdWNjZX'
        'NzEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JC'
        'CAoGcmVzdWx0');
