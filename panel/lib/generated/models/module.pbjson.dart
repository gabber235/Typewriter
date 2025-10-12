// This is a generated file - do not edit.
//
// Generated from models/module.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use moduleTypeDescriptor instead')
const ModuleType$json = {
  '1': 'ModuleType',
  '2': [
    {'1': 'MODULE_TYPE_ENGINE', '2': 0},
    {'1': 'MODULE_TYPE_EXTENSION', '2': 1},
  ],
};

/// Descriptor for `ModuleType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moduleTypeDescriptor = $convert.base64Decode(
    'CgpNb2R1bGVUeXBlEhYKEk1PRFVMRV9UWVBFX0VOR0lORRAAEhkKFU1PRFVMRV9UWVBFX0VYVE'
    'VOU0lPThAB');

@$core.Deprecated('Use moduleVersionStateDescriptor instead')
const ModuleVersionState$json = {
  '1': 'ModuleVersionState',
  '2': [
    {'1': 'MODULE_VERSION_STATE_DEVELOPING', '2': 0},
    {'1': 'MODULE_VERSION_STATE_PUBLISHED', '2': 1},
    {'1': 'MODULE_VERSION_STATE_YOINKED', '2': 2},
  ],
};

/// Descriptor for `ModuleVersionState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moduleVersionStateDescriptor = $convert.base64Decode(
    'ChJNb2R1bGVWZXJzaW9uU3RhdGUSIwofTU9EVUxFX1ZFUlNJT05fU1RBVEVfREVWRUxPUElORx'
    'AAEiIKHk1PRFVMRV9WRVJTSU9OX1NUQVRFX1BVQkxJU0hFRBABEiAKHE1PRFVMRV9WRVJTSU9O'
    'X1NUQVRFX1lPSU5LRUQQAg==');

@$core.Deprecated('Use moduleDescriptor instead')
const Module$json = {
  '1': 'Module',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.ModuleType',
      '10': 'type'
    },
    {
      '1': 'short_description',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'shortDescription'
    },
    {
      '1': 'versions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.ModuleVersion',
      '10': 'versions'
    },
  ],
};

/// Descriptor for `Module`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moduleDescriptor = $convert.base64Decode(
    'CgZNb2R1bGUSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSNAoEdHlwZRgDIA'
    'EoDjIgLnR5cGV3cml0ZXIubW9kZWxzLnYxLk1vZHVsZVR5cGVSBHR5cGUSKwoRc2hvcnRfZGVz'
    'Y3JpcHRpb24YBCABKAlSEHNob3J0RGVzY3JpcHRpb24SPwoIdmVyc2lvbnMYBSADKAsyIy50eX'
    'Bld3JpdGVyLm1vZGVscy52MS5Nb2R1bGVWZXJzaW9uUgh2ZXJzaW9ucw==');

@$core.Deprecated('Use moduleVersionDescriptor instead')
const ModuleVersion$json = {
  '1': 'ModuleVersion',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.ModuleVersionState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `ModuleVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moduleVersionDescriptor = $convert.base64Decode(
    'Cg1Nb2R1bGVWZXJzaW9uEhgKB3ZlcnNpb24YASABKAlSB3ZlcnNpb24SPgoFc3RhdGUYAiABKA'
    '4yKC50eXBld3JpdGVyLm1vZGVscy52MS5Nb2R1bGVWZXJzaW9uU3RhdGVSBXN0YXRl');
