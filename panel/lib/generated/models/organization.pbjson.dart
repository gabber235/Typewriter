// This is a generated file - do not edit.
//
// Generated from models/organization.proto.

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

@$core.Deprecated('Use organizationDataDescriptor instead')
const OrganizationData$json = {
  '1': 'OrganizationData',
  '2': [
    {'1': 'organization_id', '3': 1, '4': 1, '5': 9, '10': 'organizationId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'icon_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'iconUrl',
      '17': true
    },
    {
      '1': 'created_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_icon_url'},
  ],
};

/// Descriptor for `OrganizationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationDataDescriptor = $convert.base64Decode(
    'ChBPcmdhbml6YXRpb25EYXRhEicKD29yZ2FuaXphdGlvbl9pZBgBIAEoCVIOb3JnYW5pemF0aW'
    '9uSWQSFwoEbmFtZRgCIAEoCUgAUgRuYW1liAEBEh4KCGljb25fdXJsGAMgASgJSAFSB2ljb25V'
    'cmyIAQESOQoKY3JlYXRlZF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCW'
    'NyZWF0ZWRBdBI5Cgp1cGRhdGVkX2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt'
    'cFIJdXBkYXRlZEF0QgcKBV9uYW1lQgsKCV9pY29uX3VybA==');
