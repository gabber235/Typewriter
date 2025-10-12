// This is a generated file - do not edit.
//
// Generated from api/manual.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use listManualsRequestDescriptor instead')
const ListManualsRequest$json = {
  '1': 'ListManualsRequest',
};

/// Descriptor for `ListManualsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listManualsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0TWFudWFsc1JlcXVlc3Q=');

@$core.Deprecated('Use listManualsResponseDescriptor instead')
const ListManualsResponse$json = {
  '1': 'ListManualsResponse',
  '2': [
    {
      '1': 'manuals',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Manual',
      '10': 'manuals'
    },
  ],
};

/// Descriptor for `ListManualsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listManualsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0TWFudWFsc1Jlc3BvbnNlEjYKB21hbnVhbHMYASADKAsyHC50eXBld3JpdGVyLm1vZG'
    'Vscy52MS5NYW51YWxSB21hbnVhbHM=');

@$core.Deprecated('Use getManualRequestDescriptor instead')
const GetManualRequest$json = {
  '1': 'GetManualRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetManualRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getManualRequestDescriptor =
    $convert.base64Decode('ChBHZXRNYW51YWxSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use getManualResponseDescriptor instead')
const GetManualResponse$json = {
  '1': 'GetManualResponse',
  '2': [
    {
      '1': 'manual',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Manual',
      '9': 0,
      '10': 'manual'
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

/// Descriptor for `GetManualResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getManualResponseDescriptor = $convert.base64Decode(
    'ChFHZXRNYW51YWxSZXNwb25zZRI2CgZtYW51YWwYASABKAsyHC50eXBld3JpdGVyLm1vZGVscy'
    '52MS5NYW51YWxIAFIGbWFudWFsEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMu'
    'djEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use createManualRequestDescriptor instead')
const CreateManualRequest$json = {
  '1': 'CreateManualRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreateManualRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createManualRequestDescriptor = $convert
    .base64Decode('ChNDcmVhdGVNYW51YWxSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use createManualResponseDescriptor instead')
const CreateManualResponse$json = {
  '1': 'CreateManualResponse',
  '2': [
    {
      '1': 'manual',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Manual',
      '9': 0,
      '10': 'manual'
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

/// Descriptor for `CreateManualResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createManualResponseDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVNYW51YWxSZXNwb25zZRI2CgZtYW51YWwYASABKAsyHC50eXBld3JpdGVyLm1vZG'
    'Vscy52MS5NYW51YWxIAFIGbWFudWFsEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2Rl'
    'bHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use deleteManualRequestDescriptor instead')
const DeleteManualRequest$json = {
  '1': 'DeleteManualRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteManualRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteManualRequestDescriptor = $convert
    .base64Decode('ChNEZWxldGVNYW51YWxSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use deleteManualResponseDescriptor instead')
const DeleteManualResponse$json = {
  '1': 'DeleteManualResponse',
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

/// Descriptor for `DeleteManualResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteManualResponseDescriptor = $convert.base64Decode(
    'ChREZWxldGVNYW51YWxSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3MSMwoFZX'
    'Jyb3IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1'
    'bHQ=');

@$core.Deprecated('Use changePlatformTargetsRequestDescriptor instead')
const ChangePlatformTargetsRequest$json = {
  '1': 'ChangePlatformTargetsRequest',
  '2': [
    {'1': 'manual_id', '3': 1, '4': 1, '5': 9, '10': 'manualId'},
    {
      '1': 'proposed',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.PlatformTarget',
      '10': 'proposed'
    },
  ],
};

/// Descriptor for `ChangePlatformTargetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePlatformTargetsRequestDescriptor =
    $convert.base64Decode(
        'ChxDaGFuZ2VQbGF0Zm9ybVRhcmdldHNSZXF1ZXN0EhsKCW1hbnVhbF9pZBgBIAEoCVIIbWFudW'
        'FsSWQSQAoIcHJvcG9zZWQYAiADKAsyJC50eXBld3JpdGVyLm1vZGVscy52MS5QbGF0Zm9ybVRh'
        'cmdldFIIcHJvcG9zZWQ=');

@$core.Deprecated('Use changePlatformTargetsResponseDescriptor instead')
const ChangePlatformTargetsResponse$json = {
  '1': 'ChangePlatformTargetsResponse',
  '2': [
    {
      '1': 'manual',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Manual',
      '9': 0,
      '10': 'manual'
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

/// Descriptor for `ChangePlatformTargetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePlatformTargetsResponseDescriptor =
    $convert.base64Decode(
        'Ch1DaGFuZ2VQbGF0Zm9ybVRhcmdldHNSZXNwb25zZRI2CgZtYW51YWwYASABKAsyHC50eXBld3'
        'JpdGVyLm1vZGVscy52MS5NYW51YWxIAFIGbWFudWFsEjMKBWVycm9yGAIgASgLMhsudHlwZXdy'
        'aXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use changeModulesRequestDescriptor instead')
const ChangeModulesRequest$json = {
  '1': 'ChangeModulesRequest',
  '2': [
    {'1': 'manual_id', '3': 1, '4': 1, '5': 9, '10': 'manualId'},
    {
      '1': 'proposed',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.ManualModuleReference',
      '10': 'proposed'
    },
  ],
};

/// Descriptor for `ChangeModulesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeModulesRequestDescriptor = $convert.base64Decode(
    'ChRDaGFuZ2VNb2R1bGVzUmVxdWVzdBIbCgltYW51YWxfaWQYASABKAlSCG1hbnVhbElkEkcKCH'
    'Byb3Bvc2VkGAIgAygLMisudHlwZXdyaXRlci5tb2RlbHMudjEuTWFudWFsTW9kdWxlUmVmZXJl'
    'bmNlUghwcm9wb3NlZA==');

@$core.Deprecated('Use changeModulesResponseDescriptor instead')
const ChangeModulesResponse$json = {
  '1': 'ChangeModulesResponse',
  '2': [
    {
      '1': 'manual',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Manual',
      '9': 0,
      '10': 'manual'
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

/// Descriptor for `ChangeModulesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeModulesResponseDescriptor = $convert.base64Decode(
    'ChVDaGFuZ2VNb2R1bGVzUmVzcG9uc2USNgoGbWFudWFsGAEgASgLMhwudHlwZXdyaXRlci5tb2'
    'RlbHMudjEuTWFudWFsSABSBm1hbnVhbBIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9k'
    'ZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');
