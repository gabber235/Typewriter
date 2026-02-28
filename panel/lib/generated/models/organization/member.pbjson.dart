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
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email', '17': true},
    {
      '1': 'avatar_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'avatarUrl',
      '17': true
    },
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
  '8': [
    {'1': '_name'},
    {'1': '_email'},
    {'1': '_avatar_url'},
  ],
};

/// Descriptor for `OrganizationMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationMemberDescriptor = $convert.base64Decode(
    'ChJPcmdhbml6YXRpb25NZW1iZXISFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEhcKBG5hbWUYAi'
    'ABKAlIAFIEbmFtZYgBARIZCgVlbWFpbBgDIAEoCUgBUgVlbWFpbIgBARIiCgphdmF0YXJfdXJs'
    'GAQgASgJSAJSCWF2YXRhclVybIgBARIwCgVyb2xlcxgFIAMoCzIaLnR5cGV3cml0ZXIubW9kZW'
    'xzLnYxLlJvbGVSBXJvbGVzEjcKCWpvaW5lZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U'
    'aW1lc3RhbXBSCGpvaW5lZEF0QgcKBV9uYW1lQggKBl9lbWFpbEINCgtfYXZhdGFyX3VybA==');

@$core.Deprecated('Use joinRequestDescriptor instead')
const JoinRequest$json = {
  '1': 'JoinRequest',
  '2': [
    {'1': 'join_request_id', '3': 1, '4': 1, '5': 9, '10': 'joinRequestId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'user_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'userName',
      '17': true
    },
    {
      '1': 'user_email',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'userEmail',
      '17': true
    },
    {
      '1': 'user_avatar_url',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'userAvatarUrl',
      '17': true
    },
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
  '8': [
    {'1': '_user_name'},
    {'1': '_user_email'},
    {'1': '_user_avatar_url'},
  ],
};

/// Descriptor for `JoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinRequestDescriptor = $convert.base64Decode(
    'CgtKb2luUmVxdWVzdBImCg9qb2luX3JlcXVlc3RfaWQYASABKAlSDWpvaW5SZXF1ZXN0SWQSFw'
    'oHdXNlcl9pZBgCIAEoCVIGdXNlcklkEiAKCXVzZXJfbmFtZRgDIAEoCUgAUgh1c2VyTmFtZYgB'
    'ARIiCgp1c2VyX2VtYWlsGAQgASgJSAFSCXVzZXJFbWFpbIgBARIrCg91c2VyX2F2YXRhcl91cm'
    'wYBSABKAlIAlINdXNlckF2YXRhclVybIgBARI9CgxyZXF1ZXN0ZWRfYXQYBiABKAsyGi5nb29n'
    'bGUucHJvdG9idWYuVGltZXN0YW1wUgtyZXF1ZXN0ZWRBdBI5CgpleHBpcmVzX2F0GAcgASgLMh'
    'ouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0QgwKCl91c2VyX25hbWVCDQoL'
    'X3VzZXJfZW1haWxCEgoQX3VzZXJfYXZhdGFyX3VybA==');

@$core.Deprecated('Use userJoinRequestDescriptor instead')
const UserJoinRequest$json = {
  '1': 'UserJoinRequest',
  '2': [
    {'1': 'join_request_id', '3': 1, '4': 1, '5': 9, '10': 'joinRequestId'},
    {'1': 'organization_id', '3': 2, '4': 1, '5': 9, '10': 'organizationId'},
    {
      '1': 'organization_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'organizationName',
      '17': true
    },
    {
      '1': 'organization_icon_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'organizationIconUrl',
      '17': true
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
  '8': [
    {'1': '_organization_name'},
    {'1': '_organization_icon_url'},
  ],
};

/// Descriptor for `UserJoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userJoinRequestDescriptor = $convert.base64Decode(
    'Cg9Vc2VySm9pblJlcXVlc3QSJgoPam9pbl9yZXF1ZXN0X2lkGAEgASgJUg1qb2luUmVxdWVzdE'
    'lkEicKD29yZ2FuaXphdGlvbl9pZBgCIAEoCVIOb3JnYW5pemF0aW9uSWQSMAoRb3JnYW5pemF0'
    'aW9uX25hbWUYAyABKAlIAFIQb3JnYW5pemF0aW9uTmFtZYgBARI3ChVvcmdhbml6YXRpb25faW'
    'Nvbl91cmwYBCABKAlIAVITb3JnYW5pemF0aW9uSWNvblVybIgBARI9CgxyZXF1ZXN0ZWRfYXQY'
    'BSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtyZXF1ZXN0ZWRBdBI5CgpleHBpcm'
    'VzX2F0GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0QhQKEl9v'
    'cmdhbml6YXRpb25fbmFtZUIYChZfb3JnYW5pemF0aW9uX2ljb25fdXJs');

@$core.Deprecated('Use joinCodeDescriptor instead')
const JoinCode$json = {
  '1': 'JoinCode',
  '2': [
    {'1': 'code', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'code', '17': true},
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
    {'1': 'single_use', '3': 5, '4': 1, '5': 8, '10': 'singleUse'},
    {
      '1': 'auto_accept',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.JoinCodeAutoAccept',
      '10': 'autoAccept'
    },
  ],
  '8': [
    {'1': '_code'},
  ],
};

/// Descriptor for `JoinCode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinCodeDescriptor = $convert.base64Decode(
    'CghKb2luQ29kZRIXCgRjb2RlGAIgASgJSABSBGNvZGWIAQESOQoKY3JlYXRlZF9hdBgDIAEoCz'
    'IaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI5CgpleHBpcmVzX2F0GAQg'
    'ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0Eh0KCnNpbmdsZV91c2'
    'UYBSABKAhSCXNpbmdsZVVzZRJJCgthdXRvX2FjY2VwdBgGIAEoCzIoLnR5cGV3cml0ZXIubW9k'
    'ZWxzLnYxLkpvaW5Db2RlQXV0b0FjY2VwdFIKYXV0b0FjY2VwdEIHCgVfY29kZQ==');

@$core.Deprecated('Use joinCodeAutoAcceptDescriptor instead')
const JoinCodeAutoAccept$json = {
  '1': 'JoinCodeAutoAccept',
  '2': [
    {'1': 'role_ids', '3': 1, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `JoinCodeAutoAccept`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinCodeAutoAcceptDescriptor =
    $convert.base64Decode(
        'ChJKb2luQ29kZUF1dG9BY2NlcHQSGQoIcm9sZV9pZHMYASADKAlSB3JvbGVJZHM=');
