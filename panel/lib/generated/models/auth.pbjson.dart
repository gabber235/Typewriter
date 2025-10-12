// This is a generated file - do not edit.
//
// Generated from models/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use permissionDescriptor instead')
const Permission$json = {
  '1': 'Permission',
  '2': [
    {'1': 'allow', '3': 1, '4': 3, '5': 9, '10': 'allow'},
    {'1': 'deny', '3': 2, '4': 3, '5': 9, '10': 'deny'},
  ],
};

/// Descriptor for `Permission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionDescriptor = $convert.base64Decode(
    'CgpQZXJtaXNzaW9uEhQKBWFsbG93GAEgAygJUgVhbGxvdxISCgRkZW55GAIgAygJUgRkZW55');

@$core.Deprecated('Use responsePermissionDescriptor instead')
const ResponsePermission$json = {
  '1': 'ResponsePermission',
  '2': [
    {'1': 'max_messages', '3': 1, '4': 1, '5': 5, '10': 'maxMessages'},
    {
      '1': 'ttl',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'ttl'
    },
  ],
};

/// Descriptor for `ResponsePermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responsePermissionDescriptor = $convert.base64Decode(
    'ChJSZXNwb25zZVBlcm1pc3Npb24SIQoMbWF4X21lc3NhZ2VzGAEgASgFUgttYXhNZXNzYWdlcx'
    'IrCgN0dGwYAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SA3R0bA==');

@$core.Deprecated('Use permissionsDescriptor instead')
const Permissions$json = {
  '1': 'Permissions',
  '2': [
    {
      '1': 'publish',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Permission',
      '10': 'publish'
    },
    {
      '1': 'subscribe',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Permission',
      '10': 'subscribe'
    },
    {
      '1': 'resp',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.ResponsePermission',
      '10': 'resp'
    },
  ],
};

/// Descriptor for `Permissions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionsDescriptor = $convert.base64Decode(
    'CgtQZXJtaXNzaW9ucxI6CgdwdWJsaXNoGAEgASgLMiAudHlwZXdyaXRlci5tb2RlbHMudjEuUG'
    'VybWlzc2lvblIHcHVibGlzaBI+CglzdWJzY3JpYmUYAiABKAsyIC50eXBld3JpdGVyLm1vZGVs'
    'cy52MS5QZXJtaXNzaW9uUglzdWJzY3JpYmUSPAoEcmVzcBgDIAEoCzIoLnR5cGV3cml0ZXIubW'
    '9kZWxzLnYxLlJlc3BvbnNlUGVybWlzc2lvblIEcmVzcA==');
