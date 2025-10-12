// This is a generated file - do not edit.
//
// Generated from api/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

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
