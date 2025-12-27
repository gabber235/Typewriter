// This is a generated file - do not edit.
//
// Generated from api/service.proto.

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

@$core.Deprecated('Use issueServiceIdentityRequestDescriptor instead')
const IssueServiceIdentityRequest$json = {
  '1': 'IssueServiceIdentityRequest',
  '2': [
    {
      '1': 'service_types',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.typewriter.models.v1.ServiceType',
      '10': 'serviceTypes'
    },
    {
      '1': 'metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.ServiceMetadata',
      '10': 'metadata'
    },
  ],
};

/// Descriptor for `IssueServiceIdentityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueServiceIdentityRequestDescriptor = $convert.base64Decode(
    'ChtJc3N1ZVNlcnZpY2VJZGVudGl0eVJlcXVlc3QSRgoNc2VydmljZV90eXBlcxgCIAMoDjIhLn'
    'R5cGV3cml0ZXIubW9kZWxzLnYxLlNlcnZpY2VUeXBlUgxzZXJ2aWNlVHlwZXMSQQoIbWV0YWRh'
    'dGEYAyABKAsyJS50eXBld3JpdGVyLm1vZGVscy52MS5TZXJ2aWNlTWV0YWRhdGFSCG1ldGFkYX'
    'Rh');

@$core.Deprecated('Use issueServiceIdentityResponseDescriptor instead')
const IssueServiceIdentityResponse$json = {
  '1': 'IssueServiceIdentityResponse',
  '2': [
    {
      '1': 'credentials',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ServiceCredentials',
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

/// Descriptor for `IssueServiceIdentityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueServiceIdentityResponseDescriptor = $convert.base64Decode(
    'ChxJc3N1ZVNlcnZpY2VJZGVudGl0eVJlc3BvbnNlEkkKC2NyZWRlbnRpYWxzGAEgASgLMiUudH'
    'lwZXdyaXRlci5hcGkudjEuU2VydmljZUNyZWRlbnRpYWxzSABSC2NyZWRlbnRpYWxzEjMKBWVy'
    'cm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdW'
    'x0');

@$core.Deprecated('Use serviceCredentialsDescriptor instead')
const ServiceCredentials$json = {
  '1': 'ServiceCredentials',
  '2': [
    {'1': 'service_id', '3': 1, '4': 1, '5': 9, '10': 'serviceId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'token', '3': 3, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `ServiceCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceCredentialsDescriptor = $convert.base64Decode(
    'ChJTZXJ2aWNlQ3JlZGVudGlhbHMSHQoKc2VydmljZV9pZBgBIAEoCVIJc2VydmljZUlkEhoKCH'
    'VzZXJuYW1lGAIgASgJUgh1c2VybmFtZRIUCgV0b2tlbhgDIAEoCVIFdG9rZW4=');
