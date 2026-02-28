// This is a generated file - do not edit.
//
// Generated from api/organization/member.proto.

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

@$core.Deprecated('Use listMembersRequestDescriptor instead')
const ListMembersRequest$json = {
  '1': 'ListMembersRequest',
};

/// Descriptor for `ListMembersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMembersRequestDescriptor =
    $convert.base64Decode('ChJMaXN0TWVtYmVyc1JlcXVlc3Q=');

@$core.Deprecated('Use listMembersResponseDescriptor instead')
const ListMembersResponse$json = {
  '1': 'ListMembersResponse',
  '2': [
    {
      '1': 'members',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListMembers',
      '9': 0,
      '10': 'members'
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

/// Descriptor for `ListMembersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMembersResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0TWVtYmVyc1Jlc3BvbnNlEjoKB21lbWJlcnMYASABKAsyHi50eXBld3JpdGVyLmFwaS'
    '52MS5MaXN0TWVtYmVyc0gAUgdtZW1iZXJzEjMKBWVycm9yGAIgASgLMhsudHlwZXdyaXRlci5t'
    'b2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use listMembersDescriptor instead')
const ListMembers$json = {
  '1': 'ListMembers',
  '2': [
    {
      '1': 'members',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationMember',
      '10': 'members'
    },
  ],
};

/// Descriptor for `ListMembers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMembersDescriptor = $convert.base64Decode(
    'CgtMaXN0TWVtYmVycxJCCgdtZW1iZXJzGAEgAygLMigudHlwZXdyaXRlci5tb2RlbHMudjEuT3'
    'JnYW5pemF0aW9uTWVtYmVyUgdtZW1iZXJz');

@$core.Deprecated('Use updateMemberRolesRequestDescriptor instead')
const UpdateMemberRolesRequest$json = {
  '1': 'UpdateMemberRolesRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'role_ids', '3': 2, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `UpdateMemberRolesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMemberRolesRequestDescriptor =
    $convert.base64Decode(
        'ChhVcGRhdGVNZW1iZXJSb2xlc1JlcXVlc3QSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEhkKCH'
        'JvbGVfaWRzGAIgAygJUgdyb2xlSWRz');

@$core.Deprecated('Use updateMemberRolesResponseDescriptor instead')
const UpdateMemberRolesResponse$json = {
  '1': 'UpdateMemberRolesResponse',
  '2': [
    {
      '1': 'member',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationMember',
      '9': 0,
      '10': 'member'
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

/// Descriptor for `UpdateMemberRolesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMemberRolesResponseDescriptor = $convert.base64Decode(
    'ChlVcGRhdGVNZW1iZXJSb2xlc1Jlc3BvbnNlEkIKBm1lbWJlchgBIAEoCzIoLnR5cGV3cml0ZX'
    'IubW9kZWxzLnYxLk9yZ2FuaXphdGlvbk1lbWJlckgAUgZtZW1iZXISMwoFZXJyb3IYAiABKAsy'
    'Gy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use removeMemberRequestDescriptor instead')
const RemoveMemberRequest$json = {
  '1': 'RemoveMemberRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `RemoveMemberRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeMemberRequestDescriptor =
    $convert.base64Decode(
        'ChNSZW1vdmVNZW1iZXJSZXF1ZXN0EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZA==');

@$core.Deprecated('Use removeMemberResponseDescriptor instead')
const RemoveMemberResponse$json = {
  '1': 'RemoveMemberResponse',
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

/// Descriptor for `RemoveMemberResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeMemberResponseDescriptor = $convert.base64Decode(
    'ChRSZW1vdmVNZW1iZXJSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3MSMwoFZX'
    'Jyb3IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1'
    'bHQ=');

@$core.Deprecated('Use listJoinRequestsRequestDescriptor instead')
const ListJoinRequestsRequest$json = {
  '1': 'ListJoinRequestsRequest',
};

/// Descriptor for `ListJoinRequestsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinRequestsRequestDescriptor =
    $convert.base64Decode('ChdMaXN0Sm9pblJlcXVlc3RzUmVxdWVzdA==');

@$core.Deprecated('Use listJoinRequestsResponseDescriptor instead')
const ListJoinRequestsResponse$json = {
  '1': 'ListJoinRequestsResponse',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListJoinRequests',
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

/// Descriptor for `ListJoinRequestsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinRequestsResponseDescriptor = $convert.base64Decode(
    'ChhMaXN0Sm9pblJlcXVlc3RzUmVzcG9uc2USQQoIcmVxdWVzdHMYASABKAsyIy50eXBld3JpdG'
    'VyLmFwaS52MS5MaXN0Sm9pblJlcXVlc3RzSABSCHJlcXVlc3RzEjMKBWVycm9yGAIgASgLMhsu'
    'dHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use listJoinRequestsDescriptor instead')
const ListJoinRequests$json = {
  '1': 'ListJoinRequests',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.JoinRequest',
      '10': 'requests'
    },
  ],
};

/// Descriptor for `ListJoinRequests`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinRequestsDescriptor = $convert.base64Decode(
    'ChBMaXN0Sm9pblJlcXVlc3RzEj0KCHJlcXVlc3RzGAEgAygLMiEudHlwZXdyaXRlci5tb2RlbH'
    'MudjEuSm9pblJlcXVlc3RSCHJlcXVlc3Rz');

@$core.Deprecated('Use approveJoinRequestRequestDescriptor instead')
const ApproveJoinRequestRequest$json = {
  '1': 'ApproveJoinRequestRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'role_ids', '3': 2, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `ApproveJoinRequestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List approveJoinRequestRequestDescriptor =
    $convert.base64Decode(
        'ChlBcHByb3ZlSm9pblJlcXVlc3RSZXF1ZXN0Eh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3'
        'RJZBIZCghyb2xlX2lkcxgCIAMoCVIHcm9sZUlkcw==');

@$core.Deprecated('Use approveJoinRequestResponseDescriptor instead')
const ApproveJoinRequestResponse$json = {
  '1': 'ApproveJoinRequestResponse',
  '2': [
    {
      '1': 'member',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.OrganizationMember',
      '9': 0,
      '10': 'member'
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

/// Descriptor for `ApproveJoinRequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List approveJoinRequestResponseDescriptor =
    $convert.base64Decode(
        'ChpBcHByb3ZlSm9pblJlcXVlc3RSZXNwb25zZRJCCgZtZW1iZXIYASABKAsyKC50eXBld3JpdG'
        'VyLm1vZGVscy52MS5Pcmdhbml6YXRpb25NZW1iZXJIAFIGbWVtYmVyEjMKBWVycm9yGAIgASgL'
        'MhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use declineJoinRequestRequestDescriptor instead')
const DeclineJoinRequestRequest$json = {
  '1': 'DeclineJoinRequestRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
  ],
};

/// Descriptor for `DeclineJoinRequestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List declineJoinRequestRequestDescriptor =
    $convert.base64Decode(
        'ChlEZWNsaW5lSm9pblJlcXVlc3RSZXF1ZXN0Eh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3'
        'RJZA==');

@$core.Deprecated('Use declineJoinRequestResponseDescriptor instead')
const DeclineJoinRequestResponse$json = {
  '1': 'DeclineJoinRequestResponse',
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

/// Descriptor for `DeclineJoinRequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List declineJoinRequestResponseDescriptor =
    $convert.base64Decode(
        'ChpEZWNsaW5lSm9pblJlcXVlc3RSZXNwb25zZRIaCgdzdWNjZXNzGAEgASgISABSB3N1Y2Nlc3'
        'MSMwoFZXJyb3IYAiABKAsyGy50eXBld3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckII'
        'CgZyZXN1bHQ=');

@$core.Deprecated('Use generateJoinCodeRequestDescriptor instead')
const GenerateJoinCodeRequest$json = {
  '1': 'GenerateJoinCodeRequest',
  '2': [
    {
      '1': 'single_use',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'singleUse',
      '17': true
    },
    {
      '1': 'expiration',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.JoinCodeExpiration',
      '10': 'expiration'
    },
    {
      '1': 'auto_accept',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.JoinCodeAutoAcceptConfig',
      '10': 'autoAccept'
    },
  ],
  '8': [
    {'1': '_single_use'},
  ],
};

/// Descriptor for `GenerateJoinCodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateJoinCodeRequestDescriptor = $convert.base64Decode(
    'ChdHZW5lcmF0ZUpvaW5Db2RlUmVxdWVzdBIiCgpzaW5nbGVfdXNlGAEgASgISABSCXNpbmdsZV'
    'VzZYgBARJFCgpleHBpcmF0aW9uGAIgASgLMiUudHlwZXdyaXRlci5hcGkudjEuSm9pbkNvZGVF'
    'eHBpcmF0aW9uUgpleHBpcmF0aW9uEkwKC2F1dG9fYWNjZXB0GAMgASgLMisudHlwZXdyaXRlci'
    '5hcGkudjEuSm9pbkNvZGVBdXRvQWNjZXB0Q29uZmlnUgphdXRvQWNjZXB0Qg0KC19zaW5nbGVf'
    'dXNl');

@$core.Deprecated('Use joinCodeExpirationDescriptor instead')
const JoinCodeExpiration$json = {
  '1': 'JoinCodeExpiration',
  '2': [
    {'1': 'never', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'never'},
    {
      '1': 'duration_seconds',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'durationSeconds'
    },
  ],
  '8': [
    {'1': 'expiration'},
  ],
};

/// Descriptor for `JoinCodeExpiration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinCodeExpirationDescriptor = $convert.base64Decode(
    'ChJKb2luQ29kZUV4cGlyYXRpb24SFgoFbmV2ZXIYASABKAhIAFIFbmV2ZXISKwoQZHVyYXRpb2'
    '5fc2Vjb25kcxgCIAEoA0gAUg9kdXJhdGlvblNlY29uZHNCDAoKZXhwaXJhdGlvbg==');

@$core.Deprecated('Use joinCodeAutoAcceptConfigDescriptor instead')
const JoinCodeAutoAcceptConfig$json = {
  '1': 'JoinCodeAutoAcceptConfig',
  '2': [
    {'1': 'role_ids', '3': 1, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `JoinCodeAutoAcceptConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinCodeAutoAcceptConfigDescriptor =
    $convert.base64Decode(
        'ChhKb2luQ29kZUF1dG9BY2NlcHRDb25maWcSGQoIcm9sZV9pZHMYASADKAlSB3JvbGVJZHM=');

@$core.Deprecated('Use generateJoinCodeResponseDescriptor instead')
const GenerateJoinCodeResponse$json = {
  '1': 'GenerateJoinCodeResponse',
  '2': [
    {
      '1': 'join_code',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.JoinCode',
      '9': 0,
      '10': 'joinCode'
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

/// Descriptor for `GenerateJoinCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateJoinCodeResponseDescriptor = $convert.base64Decode(
    'ChhHZW5lcmF0ZUpvaW5Db2RlUmVzcG9uc2USPQoJam9pbl9jb2RlGAEgASgLMh4udHlwZXdyaX'
    'Rlci5tb2RlbHMudjEuSm9pbkNvZGVIAFIIam9pbkNvZGUSMwoFZXJyb3IYAiABKAsyGy50eXBl'
    'd3JpdGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use listJoinCodesRequestDescriptor instead')
const ListJoinCodesRequest$json = {
  '1': 'ListJoinCodesRequest',
};

/// Descriptor for `ListJoinCodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinCodesRequestDescriptor =
    $convert.base64Decode('ChRMaXN0Sm9pbkNvZGVzUmVxdWVzdA==');

@$core.Deprecated('Use listJoinCodesResponseDescriptor instead')
const ListJoinCodesResponse$json = {
  '1': 'ListJoinCodesResponse',
  '2': [
    {
      '1': 'join_codes',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ListJoinCodes',
      '9': 0,
      '10': 'joinCodes'
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

/// Descriptor for `ListJoinCodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinCodesResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0Sm9pbkNvZGVzUmVzcG9uc2USQQoKam9pbl9jb2RlcxgBIAEoCzIgLnR5cGV3cml0ZX'
    'IuYXBpLnYxLkxpc3RKb2luQ29kZXNIAFIJam9pbkNvZGVzEjMKBWVycm9yGAIgASgLMhsudHlw'
    'ZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVzdWx0');

@$core.Deprecated('Use listJoinCodesDescriptor instead')
const ListJoinCodes$json = {
  '1': 'ListJoinCodes',
  '2': [
    {
      '1': 'join_codes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.JoinCode',
      '10': 'joinCodes'
    },
  ],
};

/// Descriptor for `ListJoinCodes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listJoinCodesDescriptor = $convert.base64Decode(
    'Cg1MaXN0Sm9pbkNvZGVzEj0KCmpvaW5fY29kZXMYASADKAsyHi50eXBld3JpdGVyLm1vZGVscy'
    '52MS5Kb2luQ29kZVIJam9pbkNvZGVz');

@$core.Deprecated('Use revokeJoinCodeRequestDescriptor instead')
const RevokeJoinCodeRequest$json = {
  '1': 'RevokeJoinCodeRequest',
  '2': [
    {'1': 'code_id', '3': 1, '4': 1, '5': 9, '10': 'codeId'},
  ],
};

/// Descriptor for `RevokeJoinCodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeJoinCodeRequestDescriptor =
    $convert.base64Decode(
        'ChVSZXZva2VKb2luQ29kZVJlcXVlc3QSFwoHY29kZV9pZBgBIAEoCVIGY29kZUlk');

@$core.Deprecated('Use revokeJoinCodeResponseDescriptor instead')
const RevokeJoinCodeResponse$json = {
  '1': 'RevokeJoinCodeResponse',
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

/// Descriptor for `RevokeJoinCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeJoinCodeResponseDescriptor = $convert.base64Decode(
    'ChZSZXZva2VKb2luQ29kZVJlc3BvbnNlEhoKB3N1Y2Nlc3MYASABKAhIAFIHc3VjY2VzcxIzCg'
    'VlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJl'
    'c3VsdA==');
