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
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'icon', '3': 3, '4': 1, '5': 9, '10': 'icon'},
    {
      '1': 'color',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {
      '1': 'tags',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '10': 'tags'
    },
  ],
};

/// Descriptor for `Book`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bookDescriptor = $convert.base64Decode(
    'CgRCb29rEg4KAmlkGAEgASgJUgJpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSEgoEaWNvbhgDIA'
    'EoCVIEaWNvbhIxCgVjb2xvchgEIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkNvbG9yUgVj'
    'b2xvchItCgR0YWdzGAUgAygLMhkudHlwZXdyaXRlci5tb2RlbHMudjEuVGFnUgR0YWdz');

@$core.Deprecated('Use tagDescriptor instead')
const Tag$json = {
  '1': 'Tag',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'color',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {
      '1': 'parents',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Tag',
      '10': 'parents'
    },
    {
      '1': 'placement',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Placement',
      '10': 'placement'
    },
  ],
};

/// Descriptor for `Tag`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagDescriptor = $convert.base64Decode(
    'CgNUYWcSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSMQoFY29sb3IYAyABKA'
    'syGy50eXBld3JpdGVyLm1vZGVscy52MS5Db2xvclIFY29sb3ISMwoHcGFyZW50cxgEIAMoCzIZ'
    'LnR5cGV3cml0ZXIubW9kZWxzLnYxLlRhZ1IHcGFyZW50cxI9CglwbGFjZW1lbnQYBSABKAsyHy'
    '50eXBld3JpdGVyLm1vZGVscy52MS5QbGFjZW1lbnRSCXBsYWNlbWVudA==');

@$core.Deprecated('Use placementDescriptor instead')
const Placement$json = {
  '1': 'Placement',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 5, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 5, '10': 'y'},
    {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `Placement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List placementDescriptor = $convert.base64Decode(
    'CglQbGFjZW1lbnQSDAoBeBgBIAEoBVIBeBIMCgF5GAIgASgFUgF5EhQKBXdpZHRoGAMgASgFUg'
    'V3aWR0aBIWCgZoZWlnaHQYBCABKAVSBmhlaWdodA==');

@$core.Deprecated('Use pageDescriptor instead')
const Page$json = {
  '1': 'Page',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'book_id', '3': 2, '4': 1, '5': 9, '10': 'bookId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.PageType',
      '10': 'type'
    },
    {'1': 'chapter', '3': 5, '4': 1, '5': 9, '10': 'chapter'},
    {'1': 'priority', '3': 6, '4': 1, '5': 5, '10': 'priority'},
  ],
};

/// Descriptor for `Page`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pageDescriptor = $convert.base64Decode(
    'CgRQYWdlEg4KAmlkGAEgASgJUgJpZBIXCgdib29rX2lkGAIgASgJUgZib29rSWQSEgoEbmFtZR'
    'gDIAEoCVIEbmFtZRIyCgR0eXBlGAQgASgOMh4udHlwZXdyaXRlci5tb2RlbHMudjEuUGFnZVR5'
    'cGVSBHR5cGUSGAoHY2hhcHRlchgFIAEoCVIHY2hhcHRlchIaCghwcmlvcml0eRgGIAEoBVIIcH'
    'Jpb3JpdHk=');
