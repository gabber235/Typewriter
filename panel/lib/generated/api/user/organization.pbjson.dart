// This is a generated file - do not edit.
//
// Generated from api/user/organization.proto.

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

@$core.Deprecated('Use listOrganizationsRequestDescriptor instead')
const ListOrganizationsRequest$json = {
  '1': 'ListOrganizationsRequest',
};

/// Descriptor for `ListOrganizationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationsRequestDescriptor =
    $convert.base64Decode('ChhMaXN0T3JnYW5pemF0aW9uc1JlcXVlc3Q=');

@$core.Deprecated('Use listOrganizationsResponseDescriptor instead')
const ListOrganizationsResponse$json = {
  '1': 'ListOrganizationsResponse',
  '2': [
    {
      '1': 'organizations',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListOrganizations',
      '9': 0,
      '10': 'organizations'
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

/// Descriptor for `ListOrganizationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationsResponseDescriptor = $convert.base64Decode(
    'ChlMaXN0T3JnYW5pemF0aW9uc1Jlc3BvbnNlEkwKDW9yZ2FuaXphdGlvbnMYASABKAsyJC50eX'
    'Bld3JpdGVyLmFwaS52MS5MaXN0T3JnYW5pemF0aW9uc0gAUg1vcmdhbml6YXRpb25zEjMKBWVy'
    'cm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdW'
    'x0');

@$core.Deprecated('Use listOrganizationsDescriptor instead')
const ListOrganizations$json = {
  '1': 'ListOrganizations',
  '2': [
    {
      '1': 'organizations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationData',
      '10': 'organizations'
    },
  ],
};

/// Descriptor for `ListOrganizations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationsDescriptor = $convert.base64Decode(
    'ChFMaXN0T3JnYW5pemF0aW9ucxJMCg1vcmdhbml6YXRpb25zGAEgAygLMiYudHlwZXdyaXRlci'
    '5tb2RlbHMudjEuT3JnYW5pemF0aW9uRGF0YVINb3JnYW5pemF0aW9ucw==');

@$core.Deprecated('Use createOrganizationRequestDescriptor instead')
const CreateOrganizationRequest$json = {
  '1': 'CreateOrganizationRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'icon_url', '3': 2, '4': 1, '5': 9, '10': 'iconUrl'},
  ],
};

/// Descriptor for `CreateOrganizationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createOrganizationRequestDescriptor =
    $convert.base64Decode(
        'ChlDcmVhdGVPcmdhbml6YXRpb25SZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSGQoIaWNvbl'
        '91cmwYAiABKAlSB2ljb25Vcmw=');

@$core.Deprecated('Use createOrganizationResponseDescriptor instead')
const CreateOrganizationResponse$json = {
  '1': 'CreateOrganizationResponse',
  '2': [
    {
      '1': 'organization',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationData',
      '9': 0,
      '10': 'organization'
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

/// Descriptor for `CreateOrganizationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createOrganizationResponseDescriptor = $convert.base64Decode(
    'ChpDcmVhdGVPcmdhbml6YXRpb25SZXNwb25zZRJMCgxvcmdhbml6YXRpb24YASABKAsyJi50eX'
    'Bld3JpdGVyLm1vZGVscy52MS5Pcmdhbml6YXRpb25EYXRhSABSDG9yZ2FuaXphdGlvbhIzCgVl'
    'cnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJlc3'
    'VsdA==');

@$core.Deprecated('Use listUserJoinRequestsRequestDescriptor instead')
const ListUserJoinRequestsRequest$json = {
  '1': 'ListUserJoinRequestsRequest',
};

/// Descriptor for `ListUserJoinRequestsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listUserJoinRequestsRequestDescriptor =
    $convert.base64Decode('ChtMaXN0VXNlckpvaW5SZXF1ZXN0c1JlcXVlc3Q=');

@$core.Deprecated('Use listUserJoinRequestsResponseDescriptor instead')
const ListUserJoinRequestsResponse$json = {
  '1': 'ListUserJoinRequestsResponse',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListUserJoinRequests',
      '9': 0,
      '10': 'requests'
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

/// Descriptor for `ListUserJoinRequestsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listUserJoinRequestsResponseDescriptor = $convert.base64Decode(
    'ChxMaXN0VXNlckpvaW5SZXF1ZXN0c1Jlc3BvbnNlEkUKCHJlcXVlc3RzGAEgASgLMicudHlwZX'
    'dyaXRlci5hcGkudjEuTGlzdFVzZXJKb2luUmVxdWVzdHNIAFIIcmVxdWVzdHMSMwoFZXJyb3IY'
    'AiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use listUserJoinRequestsDescriptor instead')
const ListUserJoinRequests$json = {
  '1': 'ListUserJoinRequests',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.UserJoinRequest',
      '10': 'requests'
    },
  ],
};

/// Descriptor for `ListUserJoinRequests`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listUserJoinRequestsDescriptor = $convert.base64Decode(
    'ChRMaXN0VXNlckpvaW5SZXF1ZXN0cxJBCghyZXF1ZXN0cxgBIAMoCzIlLnR5cGV3cml0ZXIubW'
    '9kZWxzLnYxLlVzZXJKb2luUmVxdWVzdFIIcmVxdWVzdHM=');

@$core.Deprecated('Use requestToJoinRequestDescriptor instead')
const RequestToJoinRequest$json = {
  '1': 'RequestToJoinRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `RequestToJoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestToJoinRequestDescriptor = $convert
    .base64Decode('ChRSZXF1ZXN0VG9Kb2luUmVxdWVzdBISCgRjb2RlGAEgASgJUgRjb2Rl');

@$core.Deprecated('Use requestToJoinResponseDescriptor instead')
const RequestToJoinResponse$json = {
  '1': 'RequestToJoinResponse',
  '2': [
    {
      '1': 'success',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.RequestToJoinResult',
      '9': 0,
      '10': 'success'
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

/// Descriptor for `RequestToJoinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestToJoinResponseDescriptor = $convert.base64Decode(
    'ChVSZXF1ZXN0VG9Kb2luUmVzcG9uc2USQgoHc3VjY2VzcxgBIAEoCzImLnR5cGV3cml0ZXIuYX'
    'BpLnYxLlJlcXVlc3RUb0pvaW5SZXN1bHRIAFIHc3VjY2VzcxIzCgVlcnJvchgCIAEoCzIbLnR5'
    'cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use requestToJoinResultDescriptor instead')
const RequestToJoinResult$json = {
  '1': 'RequestToJoinResult',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.UserJoinRequest',
      '9': 0,
      '10': 'request'
    },
    {
      '1': 'member',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.AutoAcceptedMember',
      '9': 0,
      '10': 'member'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `RequestToJoinResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestToJoinResultDescriptor = $convert.base64Decode(
    'ChNSZXF1ZXN0VG9Kb2luUmVzdWx0EkEKB3JlcXVlc3QYASABKAsyJS50eXBld3JpdGVyLm1vZG'
    'Vscy52MS5Vc2VySm9pblJlcXVlc3RIAFIHcmVxdWVzdBI/CgZtZW1iZXIYAiABKAsyJS50eXBl'
    'd3JpdGVyLmFwaS52MS5BdXRvQWNjZXB0ZWRNZW1iZXJIAFIGbWVtYmVyQgkKB291dGNvbWU=');

@$core.Deprecated('Use autoAcceptedMemberDescriptor instead')
const AutoAcceptedMember$json = {
  '1': 'AutoAcceptedMember',
  '2': [
    {'1': 'organization_id', '3': 1, '4': 1, '5': 9, '10': 'organizationId'},
    {
      '1': 'organization_name',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'organizationName'
    },
    {
      '1': 'organization_icon_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'organizationIconUrl'
    },
    {
      '1': 'roles',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Role',
      '10': 'roles'
    },
  ],
};

/// Descriptor for `AutoAcceptedMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List autoAcceptedMemberDescriptor = $convert.base64Decode(
    'ChJBdXRvQWNjZXB0ZWRNZW1iZXISJwoPb3JnYW5pemF0aW9uX2lkGAEgASgJUg5vcmdhbml6YX'
    'Rpb25JZBIrChFvcmdhbml6YXRpb25fbmFtZRgCIAEoCVIQb3JnYW5pemF0aW9uTmFtZRIyChVv'
    'cmdhbml6YXRpb25faWNvbl91cmwYAyABKAlSE29yZ2FuaXphdGlvbkljb25VcmwSMAoFcm9sZX'
    'MYBCADKAsyGi50eXBld3JpdGVyLm1vZGVscy52MS5Sb2xlUgVyb2xlcw==');

@$core.Deprecated('Use cancelJoinRequestRequestDescriptor instead')
const CancelJoinRequestRequest$json = {
  '1': 'CancelJoinRequestRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
  ],
};

/// Descriptor for `CancelJoinRequestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelJoinRequestRequestDescriptor =
    $convert.base64Decode(
        'ChhDYW5jZWxKb2luUmVxdWVzdFJlcXVlc3QSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdE'
        'lk');

@$core.Deprecated('Use cancelJoinRequestResponseDescriptor instead')
const CancelJoinRequestResponse$json = {
  '1': 'CancelJoinRequestResponse',
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

/// Descriptor for `CancelJoinRequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelJoinRequestResponseDescriptor = $convert.base64Decode(
    'ChlDYW5jZWxKb2luUmVxdWVzdFJlc3BvbnNlEhoKB3N1Y2Nlc3MYASABKAhIAFIHc3VjY2Vzcx'
    'IzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggK'
    'BnJlc3VsdA==');
