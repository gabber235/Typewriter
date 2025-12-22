// This is a generated file - do not edit.
//
// Generated from api/organization/role.proto.

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

@$core.Deprecated('Use listRolesRequestDescriptor instead')
const ListRolesRequest$json = {
  '1': 'ListRolesRequest',
};

/// Descriptor for `ListRolesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRolesRequestDescriptor =
    $convert.base64Decode('ChBMaXN0Um9sZXNSZXF1ZXN0');

@$core.Deprecated('Use listRolesResponseDescriptor instead')
const ListRolesResponse$json = {
  '1': 'ListRolesResponse',
  '2': [
    {
      '1': 'roles',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListRoles',
      '9': 0,
      '10': 'roles'
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

/// Descriptor for `ListRolesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRolesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Um9sZXNSZXNwb25zZRI0CgVyb2xlcxgBIAEoCzIcLnR5cGV3cml0ZXIuYXBpLnYxLk'
    'xpc3RSb2xlc0gAUgVyb2xlcxIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYx'
    'LkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use listRolesDescriptor instead')
const ListRoles$json = {
  '1': 'ListRoles',
  '2': [
    {
      '1': 'roles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Role',
      '10': 'roles'
    },
  ],
};

/// Descriptor for `ListRoles`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRolesDescriptor = $convert.base64Decode(
    'CglMaXN0Um9sZXMSMAoFcm9sZXMYASADKAsyGi50eXBld3JpdGVyLm1vZGVscy52MS5Sb2xlUg'
    'Vyb2xlcw==');
