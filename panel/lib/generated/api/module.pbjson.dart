// This is a generated file - do not edit.
//
// Generated from api/module.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use listModulesRequestDescriptor instead')
const ListModulesRequest$json = {
  '1': 'ListModulesRequest',
};

/// Descriptor for `ListModulesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModulesRequestDescriptor =
    $convert.base64Decode('ChJMaXN0TW9kdWxlc1JlcXVlc3Q=');

@$core.Deprecated('Use listModulesResponseDescriptor instead')
const ListModulesResponse$json = {
  '1': 'ListModulesResponse',
  '2': [
    {
      '1': 'modules',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Module',
      '10': 'modules'
    },
  ],
};

/// Descriptor for `ListModulesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModulesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0TW9kdWxlc1Jlc3BvbnNlEjYKB21vZHVsZXMYASADKAsyHC50eXBld3JpdGVyLm1vZG'
    'Vscy52MS5Nb2R1bGVSB21vZHVsZXM=');

@$core.Deprecated('Use getModuleRequestDescriptor instead')
const GetModuleRequest$json = {
  '1': 'GetModuleRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetModuleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModuleRequestDescriptor =
    $convert.base64Decode('ChBHZXRNb2R1bGVSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use getModuleResponseDescriptor instead')
const GetModuleResponse$json = {
  '1': 'GetModuleResponse',
  '2': [
    {
      '1': 'module',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Module',
      '9': 0,
      '10': 'module'
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

/// Descriptor for `GetModuleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModuleResponseDescriptor = $convert.base64Decode(
    'ChFHZXRNb2R1bGVSZXNwb25zZRI2CgZtb2R1bGUYASABKAsyHC50eXBld3JpdGVyLm1vZGVscy'
    '52MS5Nb2R1bGVIAFIGbW9kdWxlEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMu'
    'djEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use updateModuleRequestDescriptor instead')
const UpdateModuleRequest$json = {
  '1': 'UpdateModuleRequest',
  '2': [
    {
      '1': 'module',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Module',
      '10': 'module'
    },
  ],
};

/// Descriptor for `UpdateModuleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateModuleRequestDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVNb2R1bGVSZXF1ZXN0EjQKBm1vZHVsZRgBIAEoCzIcLnR5cGV3cml0ZXIubW9kZW'
    'xzLnYxLk1vZHVsZVIGbW9kdWxl');

@$core.Deprecated('Use updateModuleResponseDescriptor instead')
const UpdateModuleResponse$json = {
  '1': 'UpdateModuleResponse',
  '2': [
    {
      '1': 'module',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Module',
      '9': 0,
      '10': 'module'
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

/// Descriptor for `UpdateModuleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateModuleResponseDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVNb2R1bGVSZXNwb25zZRI2CgZtb2R1bGUYASABKAsyHC50eXBld3JpdGVyLm1vZG'
    'Vscy52MS5Nb2R1bGVIAFIGbW9kdWxlEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2Rl'
    'bHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use changeVersionStateRequestDescriptor instead')
const ChangeVersionStateRequest$json = {
  '1': 'ChangeVersionStateRequest',
  '2': [
    {'1': 'module_ids', '3': 1, '4': 3, '5': 9, '10': 'moduleIds'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.ModuleVersionState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `ChangeVersionStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeVersionStateRequestDescriptor = $convert.base64Decode(
    'ChlDaGFuZ2VWZXJzaW9uU3RhdGVSZXF1ZXN0Eh0KCm1vZHVsZV9pZHMYASADKAlSCW1vZHVsZU'
    'lkcxIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEj4KBXN0YXRlGAMgASgOMigudHlwZXdyaXRl'
    'ci5tb2RlbHMudjEuTW9kdWxlVmVyc2lvblN0YXRlUgVzdGF0ZQ==');

@$core.Deprecated('Use changeVersionStateResponseDescriptor instead')
const ChangeVersionStateResponse$json = {
  '1': 'ChangeVersionStateResponse',
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

/// Descriptor for `ChangeVersionStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeVersionStateResponseDescriptor =
    $convert.base64Decode(
        'ChpDaGFuZ2VWZXJzaW9uU3RhdGVSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3'
        'MSMwoFZXJyb3IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckII'
        'CgZyZXN1bHQ=');
