// This is a generated file - do not edit.
//
// Generated from models/organization/role.proto.

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

@$core.Deprecated('Use roleDescriptor instead')
const Role$json = {
  '1': 'Role',
  '2': [
    {
      '1': 'role_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'roleId',
      '17': true
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {
      '1': 'color',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {
      '1': 'default_role',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'defaultRole',
      '17': true
    },
    {
      '1': 'assignable',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'assignable',
      '17': true
    },
    {
      '1': 'deletable',
      '3': 6,
      '4': 1,
      '5': 8,
      '9': 4,
      '10': 'deletable',
      '17': true
    },
  ],
  '8': [
    {'1': '_role_id'},
    {'1': '_name'},
    {'1': '_default_role'},
    {'1': '_assignable'},
    {'1': '_deletable'},
  ],
};

/// Descriptor for `Role`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleDescriptor = $convert.base64Decode(
    'CgRSb2xlEhwKB3JvbGVfaWQYASABKAlIAFIGcm9sZUlkiAEBEhcKBG5hbWUYAiABKAlIAVIEbm'
    'FtZYgBARIxCgVjb2xvchgDIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkNvbG9yUgVjb2xv'
    'chImCgxkZWZhdWx0X3JvbGUYBCABKAhIAlILZGVmYXVsdFJvbGWIAQESIwoKYXNzaWduYWJsZR'
    'gFIAEoCEgDUgphc3NpZ25hYmxliAEBEiEKCWRlbGV0YWJsZRgGIAEoCEgEUglkZWxldGFibGWI'
    'AQFCCgoIX3JvbGVfaWRCBwoFX25hbWVCDwoNX2RlZmF1bHRfcm9sZUINCgtfYXNzaWduYWJsZU'
    'IMCgpfZGVsZXRhYmxl');
