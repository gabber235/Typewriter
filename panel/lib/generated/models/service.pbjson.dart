// This is a generated file - do not edit.
//
// Generated from models/service.proto.

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

@$core.Deprecated('Use serviceTypeDescriptor instead')
const ServiceType$json = {
  '1': 'ServiceType',
  '2': [
    {'1': 'SERVICE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SERVICE_TYPE_ENGINE', '2': 1},
    {'1': 'SERVICE_TYPE_REALM', '2': 2},
  ],
};

/// Descriptor for `ServiceType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List serviceTypeDescriptor = $convert.base64Decode(
    'CgtTZXJ2aWNlVHlwZRIcChhTRVJWSUNFX1RZUEVfVU5TUEVDSUZJRUQQABIXChNTRVJWSUNFX1'
    'RZUEVfRU5HSU5FEAESFgoSU0VSVklDRV9UWVBFX1JFQUxNEAI=');

@$core.Deprecated('Use serviceStatusDescriptor instead')
const ServiceStatus$json = {
  '1': 'ServiceStatus',
  '2': [
    {'1': 'SERVICE_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'SERVICE_STATUS_ONLINE', '2': 1},
    {'1': 'SERVICE_STATUS_OFFLINE', '2': 2},
  ],
};

/// Descriptor for `ServiceStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List serviceStatusDescriptor = $convert.base64Decode(
    'Cg1TZXJ2aWNlU3RhdHVzEh4KGlNFUlZJQ0VfU1RBVFVTX1VOU1BFQ0lGSUVEEAASGQoVU0VSVk'
    'lDRV9TVEFUVVNfT05MSU5FEAESGgoWU0VSVklDRV9TVEFUVVNfT0ZGTElORRAC');

@$core.Deprecated('Use serviceStateDescriptor instead')
const ServiceState$json = {
  '1': 'ServiceState',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.ServiceStatus',
      '10': 'status'
    },
    {
      '1': 'last_seen',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeen'
    },
  ],
};

/// Descriptor for `ServiceState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceStateDescriptor = $convert.base64Decode(
    'CgxTZXJ2aWNlU3RhdGUSOwoGc3RhdHVzGAEgASgOMiMudHlwZXdyaXRlci5tb2RlbHMudjEuU2'
    'VydmljZVN0YXR1c1IGc3RhdHVzEjcKCWxhc3Rfc2VlbhgCIAEoCzIaLmdvb2dsZS5wcm90b2J1'
    'Zi5UaW1lc3RhbXBSCGxhc3RTZWVu');

@$core.Deprecated('Use serviceMetadataDescriptor instead')
const ServiceMetadata$json = {
  '1': 'ServiceMetadata',
  '2': [
    {
      '1': 'engine_version',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'engineVersion',
      '17': true
    },
    {
      '1': 'realm_version',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'realmVersion',
      '17': true
    },
  ],
  '8': [
    {'1': '_engine_version'},
    {'1': '_realm_version'},
  ],
};

/// Descriptor for `ServiceMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceMetadataDescriptor = $convert.base64Decode(
    'Cg9TZXJ2aWNlTWV0YWRhdGESKgoOZW5naW5lX3ZlcnNpb24YASABKAlIAFINZW5naW5lVmVyc2'
    'lvbogBARIoCg1yZWFsbV92ZXJzaW9uGAIgASgJSAFSDHJlYWxtVmVyc2lvbogBAUIRCg9fZW5n'
    'aW5lX3ZlcnNpb25CEAoOX3JlYWxtX3ZlcnNpb24=');

@$core.Deprecated('Use serviceDescriptor instead')
const Service$json = {
  '1': 'Service',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'service_types',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.typewriter.models.v1.ServiceType',
      '10': 'serviceTypes'
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
      '1': 'state',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.ServiceState',
      '10': 'state'
    },
    {
      '1': 'metadata',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.ServiceMetadata',
      '10': 'metadata'
    },
    {
      '1': 'organization_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'organizationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_organization_id'},
  ],
};

/// Descriptor for `Service`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceDescriptor = $convert.base64Decode(
    'CgdTZXJ2aWNlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEkYKDXNlcnZpY2'
    'VfdHlwZXMYAyADKA4yIS50eXBld3JpdGVyLm1vZGVscy52MS5TZXJ2aWNlVHlwZVIMc2Vydmlj'
    'ZVR5cGVzEjkKCmNyZWF0ZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg'
    'ljcmVhdGVkQXQSOAoFc3RhdGUYBSABKAsyIi50eXBld3JpdGVyLm1vZGVscy52MS5TZXJ2aWNl'
    'U3RhdGVSBXN0YXRlEkEKCG1ldGFkYXRhGAYgASgLMiUudHlwZXdyaXRlci5tb2RlbHMudjEuU2'
    'VydmljZU1ldGFkYXRhUghtZXRhZGF0YRIsCg9vcmdhbml6YXRpb25faWQYByABKAlIAFIOb3Jn'
    'YW5pemF0aW9uSWSIAQFCEgoQX29yZ2FuaXphdGlvbl9pZA==');
