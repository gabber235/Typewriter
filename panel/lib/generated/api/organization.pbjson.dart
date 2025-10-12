// This is a generated file - do not edit.
//
// Generated from api/organization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

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
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationData',
      '10': 'organizations'
    },
  ],
};

/// Descriptor for `ListOrganizationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationsResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0T3JnYW5pemF0aW9uc1Jlc3BvbnNlEkwKDW9yZ2FuaXphdGlvbnMYASADKAsyJi50eX'
        'Bld3JpdGVyLm1vZGVscy52MS5Pcmdhbml6YXRpb25EYXRhUg1vcmdhbml6YXRpb25z');

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
