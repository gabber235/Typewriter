// This is a generated file - do not edit.
//
// Generated from api/tag.proto.

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

@$core.Deprecated('Use listTagsRequestDescriptor instead')
const ListTagsRequest$json = {
  '1': 'ListTagsRequest',
};

/// Descriptor for `ListTagsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTagsRequestDescriptor =
    $convert.base64Decode('Cg9MaXN0VGFnc1JlcXVlc3Q=');

@$core.Deprecated('Use listTagsResponseDescriptor instead')
const ListTagsResponse$json = {
  '1': 'ListTagsResponse',
  '2': [
    {
      '1': 'tags',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListTags',
      '9': 0,
      '10': 'tags'
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

/// Descriptor for `ListTagsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTagsResponseDescriptor = $convert.base64Decode(
    'ChBMaXN0VGFnc1Jlc3BvbnNlEjEKBHRhZ3MYASABKAsyGy50eXBld3JpdGVyLmFwaS52MS5MaX'
    'N0VGFnc0gAUgR0YWdzEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJy'
    'b3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use listTagsDescriptor instead')
const ListTags$json = {
  '1': 'ListTags',
  '2': [
    {
      '1': 'tags',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '10': 'tags'
    },
  ],
};

/// Descriptor for `ListTags`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTagsDescriptor = $convert.base64Decode(
    'CghMaXN0VGFncxItCgR0YWdzGAEgAygLMhkudHlwZXdyaXRlci5tb2RlbHMudjEuVGFnUgR0YW'
    'dz');

@$core.Deprecated('Use getTagRequestDescriptor instead')
const GetTagRequest$json = {
  '1': 'GetTagRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTagRequestDescriptor =
    $convert.base64Decode('Cg1HZXRUYWdSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use getTagResponseDescriptor instead')
const GetTagResponse$json = {
  '1': 'GetTagResponse',
  '2': [
    {
      '1': 'tag',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '9': 0,
      '10': 'tag'
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

/// Descriptor for `GetTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTagResponseDescriptor = $convert.base64Decode(
    'Cg5HZXRUYWdSZXNwb25zZRItCgN0YWcYASABKAsyGS50eXBld3JpdGVyLm1vZGVscy52MS5UYW'
    'dIAFIDdGFnEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIF'
    'ZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use createTagRequestDescriptor instead')
const CreateTagRequest$json = {
  '1': 'CreateTagRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'color',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {'1': 'parent_ids', '3': 3, '4': 3, '5': 9, '10': 'parentIds'},
    {
      '1': 'placement',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Placement',
      '10': 'placement'
    },
  ],
};

/// Descriptor for `CreateTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTagRequestDescriptor = $convert.base64Decode(
    'ChBDcmVhdGVUYWdSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSMQoFY29sb3IYAiABKAsyGy'
    '50eXBld3JpdGVyLm1vZGVscy52MS5Db2xvclIFY29sb3ISHQoKcGFyZW50X2lkcxgDIAMoCVIJ'
    'cGFyZW50SWRzEj0KCXBsYWNlbWVudBgEIAEoCzIfLnR5cGV3cml0ZXIubW9kZWxzLnYxLlBsYW'
    'NlbWVudFIJcGxhY2VtZW50');

@$core.Deprecated('Use createTagResponseDescriptor instead')
const CreateTagResponse$json = {
  '1': 'CreateTagResponse',
  '2': [
    {
      '1': 'tag',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '9': 0,
      '10': 'tag'
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

/// Descriptor for `CreateTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTagResponseDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVUYWdSZXNwb25zZRItCgN0YWcYASABKAsyGS50eXBld3JpdGVyLm1vZGVscy52MS'
    '5UYWdIAFIDdGFnEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JI'
    'AFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use updateTagRequestDescriptor instead')
const UpdateTagRequest$json = {
  '1': 'UpdateTagRequest',
  '2': [
    {
      '1': 'tag',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '10': 'tag'
    },
  ],
};

/// Descriptor for `UpdateTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTagRequestDescriptor = $convert.base64Decode(
    'ChBVcGRhdGVUYWdSZXF1ZXN0EisKA3RhZxgBIAEoCzIZLnR5cGV3cml0ZXIubW9kZWxzLnYxLl'
    'RhZ1IDdGFn');

@$core.Deprecated('Use updateTagResponseDescriptor instead')
const UpdateTagResponse$json = {
  '1': 'UpdateTagResponse',
  '2': [
    {
      '1': 'tag',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '9': 0,
      '10': 'tag'
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

/// Descriptor for `UpdateTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTagResponseDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVUYWdSZXNwb25zZRItCgN0YWcYASABKAsyGS50eXBld3JpdGVyLm1vZGVscy52MS'
    '5UYWdIAFIDdGFnEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JI'
    'AFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use deleteTagRequestDescriptor instead')
const DeleteTagRequest$json = {
  '1': 'DeleteTagRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteTagRequestDescriptor =
    $convert.base64Decode('ChBEZWxldGVUYWdSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use deleteTagResponseDescriptor instead')
const DeleteTagResponse$json = {
  '1': 'DeleteTagResponse',
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

/// Descriptor for `DeleteTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteTagResponseDescriptor = $convert.base64Decode(
    'ChFEZWxldGVUYWdSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3MSMwoFZXJyb3'
    'IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use moveTagRequestDescriptor instead')
const MoveTagRequest$json = {
  '1': 'MoveTagRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'x', '3': 2, '4': 1, '5': 5, '10': 'x'},
    {'1': 'y', '3': 3, '4': 1, '5': 5, '10': 'y'},
  ],
};

/// Descriptor for `MoveTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveTagRequestDescriptor = $convert.base64Decode(
    'Cg5Nb3ZlVGFnUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSDAoBeBgCIAEoBVIBeBIMCgF5GAMgAS'
    'gFUgF5');

@$core.Deprecated('Use moveTagResponseDescriptor instead')
const MoveTagResponse$json = {
  '1': 'MoveTagResponse',
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

/// Descriptor for `MoveTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveTagResponseDescriptor = $convert.base64Decode(
    'Cg9Nb3ZlVGFnUmVzcG9uc2USGgoHc3VjY2VzcxgBIAEoCEgAUgdzdWNjZXNzEjMKBWVycm9yGA'
    'IgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use resizeTagRequestDescriptor instead')
const ResizeTagRequest$json = {
  '1': 'ResizeTagRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'width', '3': 2, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `ResizeTagRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resizeTagRequestDescriptor = $convert.base64Decode(
    'ChBSZXNpemVUYWdSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIUCgV3aWR0aBgCIAEoBVIFd2lkdG'
    'gSFgoGaGVpZ2h0GAMgASgFUgZoZWlnaHQ=');

@$core.Deprecated('Use resizeTagResponseDescriptor instead')
const ResizeTagResponse$json = {
  '1': 'ResizeTagResponse',
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

/// Descriptor for `ResizeTagResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resizeTagResponseDescriptor = $convert.base64Decode(
    'ChFSZXNpemVUYWdSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3MSMwoFZXJyb3'
    'IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');
