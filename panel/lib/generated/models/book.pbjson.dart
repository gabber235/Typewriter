// This is a generated file - do not edit.
//
// Generated from models/book.proto.

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

@$core.Deprecated('Use pageTypeDescriptor instead')
const PageType$json = {
  '1': 'PageType',
  '2': [
    {'1': 'PAGE_TYPE_SEQUENCE', '2': 0},
    {'1': 'PAGE_TYPE_STATIC', '2': 1},
    {'1': 'PAGE_TYPE_SCENE', '2': 2},
    {'1': 'PAGE_TYPE_MANIFEST', '2': 3},
  ],
};

/// Descriptor for `PageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pageTypeDescriptor = $convert.base64Decode(
    'CghQYWdlVHlwZRIWChJQQUdFX1RZUEVfU0VRVUVOQ0UQABIUChBQQUdFX1RZUEVfU1RBVElDEA'
    'ESEwoPUEFHRV9UWVBFX1NDRU5FEAISFgoSUEFHRV9UWVBFX01BTklGRVNUEAM=');

@$core.Deprecated('Use bookDescriptor instead')
const Book$json = {
  '1': 'Book',
  '2': [
    {'1': 'book_id', '3': 1, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'title', '17': true},
    {'1': 'icon', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'icon', '17': true},
    {
      '1': 'color',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {'1': 'tagIds', '3': 5, '4': 3, '5': 9, '10': 'tagIds'},
  ],
  '8': [
    {'1': '_title'},
    {'1': '_icon'},
  ],
};

/// Descriptor for `Book`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bookDescriptor = $convert.base64Decode(
    'CgRCb29rEhcKB2Jvb2tfaWQYASABKAlSBmJvb2tJZBIZCgV0aXRsZRgCIAEoCUgAUgV0aXRsZY'
    'gBARIXCgRpY29uGAMgASgJSAFSBGljb26IAQESMQoFY29sb3IYBCABKAsyGy50eXBld3JpdGVy'
    'Lm1vZGVscy52MS5Db2xvclIFY29sb3ISFgoGdGFnSWRzGAUgAygJUgZ0YWdJZHNCCAoGX3RpdG'
    'xlQgcKBV9pY29u');

@$core.Deprecated('Use tagDescriptor instead')
const Tag$json = {
  '1': 'Tag',
  '2': [
    {'1': 'tag_id', '3': 1, '4': 1, '5': 9, '10': 'tagId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'color',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {'1': 'parentIds', '3': 4, '4': 3, '5': 9, '10': 'parentIds'},
    {
      '1': 'placement',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Placement',
      '10': 'placement'
    },
  ],
  '8': [
    {'1': '_name'},
  ],
};

/// Descriptor for `Tag`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagDescriptor = $convert.base64Decode(
    'CgNUYWcSFQoGdGFnX2lkGAEgASgJUgV0YWdJZBIXCgRuYW1lGAIgASgJSABSBG5hbWWIAQESMQ'
    'oFY29sb3IYAyABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5Db2xvclIFY29sb3ISHAoJcGFy'
    'ZW50SWRzGAQgAygJUglwYXJlbnRJZHMSPQoJcGxhY2VtZW50GAUgASgLMh8udHlwZXdyaXRlci'
    '5tb2RlbHMudjEuUGxhY2VtZW50UglwbGFjZW1lbnRCBwoFX25hbWU=');

@$core.Deprecated('Use placementDescriptor instead')
const Placement$json = {
  '1': 'Placement',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 5, '9': 0, '10': 'x', '17': true},
    {'1': 'y', '3': 2, '4': 1, '5': 5, '9': 1, '10': 'y', '17': true},
    {'1': 'width', '3': 3, '4': 1, '5': 5, '9': 2, '10': 'width', '17': true},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '9': 3, '10': 'height', '17': true},
  ],
  '8': [
    {'1': '_x'},
    {'1': '_y'},
    {'1': '_width'},
    {'1': '_height'},
  ],
};

/// Descriptor for `Placement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List placementDescriptor = $convert.base64Decode(
    'CglQbGFjZW1lbnQSEQoBeBgBIAEoBUgAUgF4iAEBEhEKAXkYAiABKAVIAVIBeYgBARIZCgV3aW'
    'R0aBgDIAEoBUgCUgV3aWR0aIgBARIbCgZoZWlnaHQYBCABKAVIA1IGaGVpZ2h0iAEBQgQKAl94'
    'QgQKAl95QggKBl93aWR0aEIJCgdfaGVpZ2h0');

@$core.Deprecated('Use pageDescriptor instead')
const Page$json = {
  '1': 'Page',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'book_id', '3': 2, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.PageType',
      '10': 'type'
    },
    {
      '1': 'chapter',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'chapter',
      '17': true
    },
    {
      '1': 'priority',
      '3': 6,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'priority',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_chapter'},
    {'1': '_priority'},
  ],
};

/// Descriptor for `Page`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pageDescriptor = $convert.base64Decode(
    'CgRQYWdlEhcKB3BhZ2VfaWQYASABKAlSBnBhZ2VJZBIXCgdib29rX2lkGAIgASgJUgZib29rSW'
    'QSFwoEbmFtZRgDIAEoCUgAUgRuYW1liAEBEjIKBHR5cGUYBCABKA4yHi50eXBld3JpdGVyLm1v'
    'ZGVscy52MS5QYWdlVHlwZVIEdHlwZRIdCgdjaGFwdGVyGAUgASgJSAFSB2NoYXB0ZXKIAQESHw'
    'oIcHJpb3JpdHkYBiABKAVIAlIIcHJpb3JpdHmIAQFCBwoFX25hbWVCCgoIX2NoYXB0ZXJCCwoJ'
    'X3ByaW9yaXR5');
