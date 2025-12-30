// This is a generated file - do not edit.
//
// Generated from api/auth.proto.

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

@$core.Deprecated('Use permissionRequestDescriptor instead')
const PermissionRequest$json = {
  '1': 'PermissionRequest',
  '2': [
    {
      '1': 'organization_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'organizationId',
      '17': true
    },
    {'1': 'jwt_claims', '3': 2, '4': 1, '5': 12, '10': 'jwtClaims'},
  ],
  '8': [
    {'1': '_organization_id'},
  ],
};

/// Descriptor for `PermissionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionRequestDescriptor = $convert.base64Decode(
    'ChFQZXJtaXNzaW9uUmVxdWVzdBIsCg9vcmdhbml6YXRpb25faWQYASABKAlIAFIOb3JnYW5pem'
    'F0aW9uSWSIAQESHQoKand0X2NsYWltcxgCIAEoDFIJand0Q2xhaW1zQhIKEF9vcmdhbml6YXRp'
    'b25faWQ=');

@$core.Deprecated('Use permissionResponseDescriptor instead')
const PermissionResponse$json = {
  '1': 'PermissionResponse',
  '2': [
    {
      '1': 'permissions',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Permissions',
      '10': 'permissions'
    },
    {'1': 'tags', '3': 2, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `PermissionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionResponseDescriptor = $convert.base64Decode(
    'ChJQZXJtaXNzaW9uUmVzcG9uc2USQwoLcGVybWlzc2lvbnMYASABKAsyIS50eXBld3JpdGVyLm'
    '1vZGVscy52MS5QZXJtaXNzaW9uc1ILcGVybWlzc2lvbnMSEgoEdGFncxgCIAMoCVIEdGFncw==');

@$core.Deprecated('Use getSentinelCredentialsRequestDescriptor instead')
const GetSentinelCredentialsRequest$json = {
  '1': 'GetSentinelCredentialsRequest',
};

/// Descriptor for `GetSentinelCredentialsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSentinelCredentialsRequestDescriptor =
    $convert.base64Decode('Ch1HZXRTZW50aW5lbENyZWRlbnRpYWxzUmVxdWVzdA==');

@$core.Deprecated('Use getSentinelCredentialsResponseDescriptor instead')
const GetSentinelCredentialsResponse$json = {
  '1': 'GetSentinelCredentialsResponse',
  '2': [
    {
      '1': 'credentials',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.SentinelCredentials',
      '9': 0,
      '10': 'credentials'
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

/// Descriptor for `GetSentinelCredentialsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSentinelCredentialsResponseDescriptor =
    $convert.base64Decode(
        'Ch5HZXRTZW50aW5lbENyZWRlbnRpYWxzUmVzcG9uc2USSgoLY3JlZGVudGlhbHMYASABKAsyJi'
        '50eXBld3JpdGVyLmFwaS52MS5TZW50aW5lbENyZWRlbnRpYWxzSABSC2NyZWRlbnRpYWxzEjMK'
        'BWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcm'
        'VzdWx0');

@$core.Deprecated('Use sentinelCredentialsDescriptor instead')
const SentinelCredentials$json = {
  '1': 'SentinelCredentials',
  '2': [
    {'1': 'jwt', '3': 1, '4': 1, '5': 9, '10': 'jwt'},
    {'1': 'seed', '3': 2, '4': 1, '5': 9, '10': 'seed'},
  ],
};

/// Descriptor for `SentinelCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sentinelCredentialsDescriptor = $convert.base64Decode(
    'ChNTZW50aW5lbENyZWRlbnRpYWxzEhAKA2p3dBgBIAEoCVIDand0EhIKBHNlZWQYAiABKAlSBH'
    'NlZWQ=');
