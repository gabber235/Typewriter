// This is a generated file - do not edit.
//
// Generated from api/service/registration.proto.

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

@$core.Deprecated('Use getServiceStatusRequestDescriptor instead')
const GetServiceStatusRequest$json = {
  '1': 'GetServiceStatusRequest',
};

/// Descriptor for `GetServiceStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getServiceStatusRequestDescriptor =
    $convert.base64Decode('ChdHZXRTZXJ2aWNlU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use getServiceStatusResponseDescriptor instead')
const GetServiceStatusResponse$json = {
  '1': 'GetServiceStatusResponse',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.ServiceStatus',
      '9': 0,
      '10': 'status'
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

/// Descriptor for `GetServiceStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getServiceStatusResponseDescriptor = $convert.base64Decode(
    'ChhHZXRTZXJ2aWNlU3RhdHVzUmVzcG9uc2USOgoGc3RhdHVzGAEgASgLMiAudHlwZXdyaXRlci'
    '5hcGkudjEuU2VydmljZVN0YXR1c0gAUgZzdGF0dXMSMwoFZXJyb3IYAiABKAsyGy50eXBld3Jp'
    'dGVyLm1vZGVscy52MS5FcnJvckgAUgVlcnJvckIICgZyZXN1bHQ=');

@$core.Deprecated('Use serviceStatusDescriptor instead')
const ServiceStatus$json = {
  '1': 'ServiceStatus',
  '2': [
    {
      '1': 'bound',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.BoundStatus',
      '9': 0,
      '10': 'bound'
    },
    {
      '1': 'unbound',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.UnboundStatus',
      '9': 0,
      '10': 'unbound'
    },
  ],
  '8': [
    {'1': 'binding'},
  ],
};

/// Descriptor for `ServiceStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceStatusDescriptor = $convert.base64Decode(
    'Cg1TZXJ2aWNlU3RhdHVzEjYKBWJvdW5kGAEgASgLMh4udHlwZXdyaXRlci5hcGkudjEuQm91bm'
    'RTdGF0dXNIAFIFYm91bmQSPAoHdW5ib3VuZBgCIAEoCzIgLnR5cGV3cml0ZXIuYXBpLnYxLlVu'
    'Ym91bmRTdGF0dXNIAFIHdW5ib3VuZEIJCgdiaW5kaW5n');

@$core.Deprecated('Use boundStatusDescriptor instead')
const BoundStatus$json = {
  '1': 'BoundStatus',
  '2': [
    {'1': 'organization_id', '3': 1, '4': 1, '5': 9, '10': 'organizationId'},
    {
      '1': 'organization_name',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'organizationName'
    },
  ],
};

/// Descriptor for `BoundStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boundStatusDescriptor = $convert.base64Decode(
    'CgtCb3VuZFN0YXR1cxInCg9vcmdhbml6YXRpb25faWQYASABKAlSDm9yZ2FuaXphdGlvbklkEi'
    'sKEW9yZ2FuaXphdGlvbl9uYW1lGAIgASgJUhBvcmdhbml6YXRpb25OYW1l');

@$core.Deprecated('Use unboundStatusDescriptor instead')
const UnboundStatus$json = {
  '1': 'UnboundStatus',
  '2': [
    {
      '1': 'registration_token',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'registrationToken'
    },
  ],
};

/// Descriptor for `UnboundStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unboundStatusDescriptor = $convert.base64Decode(
    'Cg1VbmJvdW5kU3RhdHVzEi0KEnJlZ2lzdHJhdGlvbl90b2tlbhgBIAEoCVIRcmVnaXN0cmF0aW'
    '9uVG9rZW4=');

@$core.Deprecated('Use bindServiceRequestDescriptor instead')
const BindServiceRequest$json = {
  '1': 'BindServiceRequest',
  '2': [
    {
      '1': 'registration_token',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'registrationToken'
    },
  ],
};

/// Descriptor for `BindServiceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bindServiceRequestDescriptor = $convert.base64Decode(
    'ChJCaW5kU2VydmljZVJlcXVlc3QSLQoScmVnaXN0cmF0aW9uX3Rva2VuGAEgASgJUhFyZWdpc3'
    'RyYXRpb25Ub2tlbg==');

@$core.Deprecated('Use bindServiceResponseDescriptor instead')
const BindServiceResponse$json = {
  '1': 'BindServiceResponse',
  '2': [
    {
      '1': 'service',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.BoundService',
      '9': 0,
      '10': 'service'
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

/// Descriptor for `BindServiceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bindServiceResponseDescriptor = $convert.base64Decode(
    'ChNCaW5kU2VydmljZVJlc3BvbnNlEjsKB3NlcnZpY2UYASABKAsyHy50eXBld3JpdGVyLmFwaS'
    '52MS5Cb3VuZFNlcnZpY2VIAFIHc2VydmljZRIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIu'
    'bW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use boundServiceDescriptor instead')
const BoundService$json = {
  '1': 'BoundService',
  '2': [
    {'1': 'service_id', '3': 1, '4': 1, '5': 9, '10': 'serviceId'},
    {'1': 'service_name', '3': 2, '4': 1, '5': 9, '10': 'serviceName'},
    {
      '1': 'service_types',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.typewriter.models.v1.ServiceType',
      '10': 'serviceTypes'
    },
  ],
};

/// Descriptor for `BoundService`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boundServiceDescriptor = $convert.base64Decode(
    'CgxCb3VuZFNlcnZpY2USHQoKc2VydmljZV9pZBgBIAEoCVIJc2VydmljZUlkEiEKDHNlcnZpY2'
    'VfbmFtZRgCIAEoCVILc2VydmljZU5hbWUSRgoNc2VydmljZV90eXBlcxgDIAMoDjIhLnR5cGV3'
    'cml0ZXIubW9kZWxzLnYxLlNlcnZpY2VUeXBlUgxzZXJ2aWNlVHlwZXM=');

@$core.Deprecated('Use listOrganizationServicesRequestDescriptor instead')
const ListOrganizationServicesRequest$json = {
  '1': 'ListOrganizationServicesRequest',
};

/// Descriptor for `ListOrganizationServicesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationServicesRequestDescriptor =
    $convert.base64Decode('Ch9MaXN0T3JnYW5pemF0aW9uU2VydmljZXNSZXF1ZXN0');

@$core.Deprecated('Use listOrganizationServicesResponseDescriptor instead')
const ListOrganizationServicesResponse$json = {
  '1': 'ListOrganizationServicesResponse',
  '2': [
    {
      '1': 'services',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.api.v1.OrganizationServicesList',
      '9': 0,
      '10': 'services'
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

/// Descriptor for `ListOrganizationServicesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listOrganizationServicesResponseDescriptor =
    $convert.base64Decode(
        'CiBMaXN0T3JnYW5pemF0aW9uU2VydmljZXNSZXNwb25zZRJJCghzZXJ2aWNlcxgBIAEoCzIrLn'
        'R5cGV3cml0ZXIuYXBpLnYxLk9yZ2FuaXphdGlvblNlcnZpY2VzTGlzdEgAUghzZXJ2aWNlcxIz'
        'CgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBn'
        'Jlc3VsdA==');

@$core.Deprecated('Use organizationServicesListDescriptor instead')
const OrganizationServicesList$json = {
  '1': 'OrganizationServicesList',
  '2': [
    {
      '1': 'services',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Service',
      '10': 'services'
    },
  ],
};

/// Descriptor for `OrganizationServicesList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationServicesListDescriptor =
    $convert.base64Decode(
        'ChhPcmdhbml6YXRpb25TZXJ2aWNlc0xpc3QSOQoIc2VydmljZXMYASADKAsyHS50eXBld3JpdG'
        'VyLm1vZGVscy52MS5TZXJ2aWNlUghzZXJ2aWNlcw==');

@$core.Deprecated('Use serviceBoundNotificationDescriptor instead')
const ServiceBoundNotification$json = {
  '1': 'ServiceBoundNotification',
  '2': [
    {'1': 'organization_id', '3': 1, '4': 1, '5': 9, '10': 'organizationId'},
    {
      '1': 'organization_name',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'organizationName'
    },
  ],
};

/// Descriptor for `ServiceBoundNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceBoundNotificationDescriptor = $convert.base64Decode(
    'ChhTZXJ2aWNlQm91bmROb3RpZmljYXRpb24SJwoPb3JnYW5pemF0aW9uX2lkGAEgASgJUg5vcm'
    'dhbml6YXRpb25JZBIrChFvcmdhbml6YXRpb25fbmFtZRgCIAEoCVIQb3JnYW5pemF0aW9uTmFt'
    'ZQ==');

@$core.Deprecated('Use updateServiceRequestDescriptor instead')
const UpdateServiceRequest$json = {
  '1': 'UpdateServiceRequest',
  '2': [
    {'1': 'service_id', '3': 1, '4': 1, '5': 9, '10': 'serviceId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `UpdateServiceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateServiceRequestDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVTZXJ2aWNlUmVxdWVzdBIdCgpzZXJ2aWNlX2lkGAEgASgJUglzZXJ2aWNlSWQSEg'
    'oEbmFtZRgCIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use updateServiceResponseDescriptor instead')
const UpdateServiceResponse$json = {
  '1': 'UpdateServiceResponse',
  '2': [
    {
      '1': 'service',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Service',
      '9': 0,
      '10': 'service'
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

/// Descriptor for `UpdateServiceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateServiceResponseDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVTZXJ2aWNlUmVzcG9uc2USOQoHc2VydmljZRgBIAEoCzIdLnR5cGV3cml0ZXIubW'
    '9kZWxzLnYxLlNlcnZpY2VIAFIHc2VydmljZRIzCgVlcnJvchgCIAEoCzIbLnR5cGV3cml0ZXIu'
    'bW9kZWxzLnYxLkVycm9ySABSBWVycm9yQggKBnJlc3VsdA==');

@$core.Deprecated('Use unbindServiceRequestDescriptor instead')
const UnbindServiceRequest$json = {
  '1': 'UnbindServiceRequest',
  '2': [
    {'1': 'service_id', '3': 1, '4': 1, '5': 9, '10': 'serviceId'},
  ],
};

/// Descriptor for `UnbindServiceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unbindServiceRequestDescriptor = $convert.base64Decode(
    'ChRVbmJpbmRTZXJ2aWNlUmVxdWVzdBIdCgpzZXJ2aWNlX2lkGAEgASgJUglzZXJ2aWNlSWQ=');

@$core.Deprecated('Use unbindServiceResponseDescriptor instead')
const UnbindServiceResponse$json = {
  '1': 'UnbindServiceResponse',
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

/// Descriptor for `UnbindServiceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unbindServiceResponseDescriptor = $convert.base64Decode(
    'ChVVbmJpbmRTZXJ2aWNlUmVzcG9uc2USGgoHc3VjY2VzcxgBIAEoCEgAUgdzdWNjZXNzEjMKBW'
    'Vycm9yGAIgASgLMhsudHlwZXdyaXRlci5tb2RlbHMudjEuRXJyb3JIAFIFZXJyb3JCCAoGcmVz'
    'dWx0');

@$core.Deprecated('Use serviceHeartbeatRequestDescriptor instead')
const ServiceHeartbeatRequest$json = {
  '1': 'ServiceHeartbeatRequest',
};

/// Descriptor for `ServiceHeartbeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceHeartbeatRequestDescriptor =
    $convert.base64Decode('ChdTZXJ2aWNlSGVhcnRiZWF0UmVxdWVzdA==');

@$core.Deprecated('Use serviceShutdownRequestDescriptor instead')
const ServiceShutdownRequest$json = {
  '1': 'ServiceShutdownRequest',
};

/// Descriptor for `ServiceShutdownRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serviceShutdownRequestDescriptor =
    $convert.base64Decode('ChZTZXJ2aWNlU2h1dGRvd25SZXF1ZXN0');
