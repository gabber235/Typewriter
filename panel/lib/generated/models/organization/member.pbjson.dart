// This is a generated file - do not edit.
//
// Generated from models/organization/member.proto.

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

@$core.Deprecated('Use organizationMemberDescriptor instead')
const OrganizationMember$json = {
  '1': 'OrganizationMember',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {
      '1': 'roles',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Role',
      '10': 'roles'
    },
    {
      '1': 'joined_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'joinedAt'
    },
  ],
};

/// Descriptor for `OrganizationMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationMemberDescriptor = $convert.base64Decode(
    'ChJPcmdhbml6YXRpb25NZW1iZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USFAoFZW1haWwYAyABKAlSBWVtYWlsEh0KCmF2YXRhcl91cmwYBCABKAlSCWF2YXRhclVybBIw'
    'CgVyb2xlcxgFIAMoCzIaLnR5cGV3cml0ZXIubW9kZWxzLnYxLlJvbGVSBXJvbGVzEjcKCWpvaW'
    '5lZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCGpvaW5lZEF0');

@$core.Deprecated('Use joinRequestDescriptor instead')
const JoinRequest$json = {
  '1': 'JoinRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'user_name', '3': 3, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'user_email', '3': 4, '4': 1, '5': 9, '10': 'userEmail'},
    {'1': 'user_avatar_url', '3': 5, '4': 1, '5': 9, '10': 'userAvatarUrl'},
    {
      '1': 'requested_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'requestedAt'
    },
    {
      '1': 'expires_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
  ],
};

/// Descriptor for `JoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinRequestDescriptor = $convert.base64Decode(
    'CgtKb2luUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFwoHdXNlcl9pZBgCIAEoCVIGdXNlcklkEh'
    'sKCXVzZXJfbmFtZRgDIAEoCVIIdXNlck5hbWUSHQoKdXNlcl9lbWFpbBgEIAEoCVIJdXNlckVt'
    'YWlsEiYKD3VzZXJfYXZhdGFyX3VybBgFIAEoCVINdXNlckF2YXRhclVybBI9CgxyZXF1ZXN0ZW'
    'RfYXQYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtyZXF1ZXN0ZWRBdBI5Cgpl'
    'eHBpcmVzX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0');

@$core.Deprecated('Use userJoinRequestDescriptor instead')
const UserJoinRequest$json = {
  '1': 'UserJoinRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'organization_id', '3': 2, '4': 1, '5': 9, '10': 'organizationId'},
    {
      '1': 'organization_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'organizationName'
    },
    {
      '1': 'organization_icon_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'organizationIconUrl'
    },
    {
      '1': 'requested_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'requestedAt'
    },
    {
      '1': 'expires_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
  ],
};

/// Descriptor for `UserJoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userJoinRequestDescriptor = $convert.base64Decode(
    'Cg9Vc2VySm9pblJlcXVlc3QSDgoCaWQYASABKAlSAmlkEicKD29yZ2FuaXphdGlvbl9pZBgCIA'
    'EoCVIOb3JnYW5pemF0aW9uSWQSKwoRb3JnYW5pemF0aW9uX25hbWUYAyABKAlSEG9yZ2FuaXph'
    'dGlvbk5hbWUSMgoVb3JnYW5pemF0aW9uX2ljb25fdXJsGAQgASgJUhNvcmdhbml6YXRpb25JY2'
    '9uVXJsEj0KDHJlcXVlc3RlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS'
    'C3JlcXVlc3RlZEF0EjkKCmV4cGlyZXNfYXQYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZX'
    'N0YW1wUglleHBpcmVzQXQ=');

@$core.Deprecated('Use joinCodeDescriptor instead')
const JoinCode$json = {
  '1': 'JoinCode',
  '2': [
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {
      '1': 'created_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'expires_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
  ],
};

/// Descriptor for `JoinCode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinCodeDescriptor = $convert.base64Decode(
    'CghKb2luQ29kZRISCgRjb2RlGAIgASgJUgRjb2RlEjkKCmNyZWF0ZWRfYXQYAyABKAsyGi5nb2'
    '9nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKZXhwaXJlc19hdBgEIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWV4cGlyZXNBdA==');
