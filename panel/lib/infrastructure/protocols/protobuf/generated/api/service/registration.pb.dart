// This is a generated file - do not edit.
//
// Generated from api/service/registration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../models/common.pb.dart' as $0;
import '../../models/service.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// GetServiceStatusRequest queries a service's binding status.
/// Service ID is extracted from the NATS subject.
class GetServiceStatusRequest extends $pb.GeneratedMessage {
  factory GetServiceStatusRequest() => create();

  GetServiceStatusRequest._();

  factory GetServiceStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetServiceStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetServiceStatusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceStatusRequest copyWith(
          void Function(GetServiceStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetServiceStatusRequest))
          as GetServiceStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetServiceStatusRequest create() => GetServiceStatusRequest._();
  @$core.override
  GetServiceStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetServiceStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetServiceStatusRequest>(create);
  static GetServiceStatusRequest? _defaultInstance;
}

enum GetServiceStatusResponse_Result { status, error, notSet }

/// GetServiceStatusResponse returns the service's binding status.
class GetServiceStatusResponse extends $pb.GeneratedMessage {
  factory GetServiceStatusResponse({
    ServiceStatus? status,
    $0.Error? error,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (error != null) result.error = error;
    return result;
  }

  GetServiceStatusResponse._();

  factory GetServiceStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetServiceStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GetServiceStatusResponse_Result>
      _GetServiceStatusResponse_ResultByTag = {
    1: GetServiceStatusResponse_Result.status,
    2: GetServiceStatusResponse_Result.error,
    0: GetServiceStatusResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetServiceStatusResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ServiceStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: ServiceStatus.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceStatusResponse copyWith(
          void Function(GetServiceStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetServiceStatusResponse))
          as GetServiceStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetServiceStatusResponse create() => GetServiceStatusResponse._();
  @$core.override
  GetServiceStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetServiceStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetServiceStatusResponse>(create);
  static GetServiceStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GetServiceStatusResponse_Result whichResult() =>
      _GetServiceStatusResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ServiceStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ServiceStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ServiceStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

enum ServiceStatus_Binding { bound, unbound, notSet }

/// ServiceStatus indicates whether a service is bound to an organization.
class ServiceStatus extends $pb.GeneratedMessage {
  factory ServiceStatus({
    BoundStatus? bound,
    UnboundStatus? unbound,
  }) {
    final result = create();
    if (bound != null) result.bound = bound;
    if (unbound != null) result.unbound = unbound;
    return result;
  }

  ServiceStatus._();

  factory ServiceStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServiceStatus_Binding>
      _ServiceStatus_BindingByTag = {
    1: ServiceStatus_Binding.bound,
    2: ServiceStatus_Binding.unbound,
    0: ServiceStatus_Binding.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<BoundStatus>(1, _omitFieldNames ? '' : 'bound',
        subBuilder: BoundStatus.create)
    ..aOM<UnboundStatus>(2, _omitFieldNames ? '' : 'unbound',
        subBuilder: UnboundStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceStatus copyWith(void Function(ServiceStatus) updates) =>
      super.copyWith((message) => updates(message as ServiceStatus))
          as ServiceStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceStatus create() => ServiceStatus._();
  @$core.override
  ServiceStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceStatus>(create);
  static ServiceStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ServiceStatus_Binding whichBinding() =>
      _ServiceStatus_BindingByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearBinding() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BoundStatus get bound => $_getN(0);
  @$pb.TagNumber(1)
  set bound(BoundStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBound() => $_has(0);
  @$pb.TagNumber(1)
  void clearBound() => $_clearField(1);
  @$pb.TagNumber(1)
  BoundStatus ensureBound() => $_ensure(0);

  @$pb.TagNumber(2)
  UnboundStatus get unbound => $_getN(1);
  @$pb.TagNumber(2)
  set unbound(UnboundStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUnbound() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnbound() => $_clearField(2);
  @$pb.TagNumber(2)
  UnboundStatus ensureUnbound() => $_ensure(1);
}

/// BoundStatus indicates the service is bound to an organization.
class BoundStatus extends $pb.GeneratedMessage {
  factory BoundStatus({
    $core.String? organizationId,
    $core.String? organizationName,
  }) {
    final result = create();
    if (organizationId != null) result.organizationId = organizationId;
    if (organizationName != null) result.organizationName = organizationName;
    return result;
  }

  BoundStatus._();

  factory BoundStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoundStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoundStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'organizationId')
    ..aOS(2, _omitFieldNames ? '' : 'organizationName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundStatus copyWith(void Function(BoundStatus) updates) =>
      super.copyWith((message) => updates(message as BoundStatus))
          as BoundStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoundStatus create() => BoundStatus._();
  @$core.override
  BoundStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoundStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BoundStatus>(create);
  static BoundStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get organizationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set organizationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganizationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganizationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get organizationName => $_getSZ(1);
  @$pb.TagNumber(2)
  set organizationName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrganizationName() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrganizationName() => $_clearField(2);
}

/// UnboundStatus indicates the service needs registration.
class UnboundStatus extends $pb.GeneratedMessage {
  factory UnboundStatus({
    $core.String? registrationToken,
  }) {
    final result = create();
    if (registrationToken != null) result.registrationToken = registrationToken;
    return result;
  }

  UnboundStatus._();

  factory UnboundStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnboundStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnboundStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'registrationToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnboundStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnboundStatus copyWith(void Function(UnboundStatus) updates) =>
      super.copyWith((message) => updates(message as UnboundStatus))
          as UnboundStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnboundStatus create() => UnboundStatus._();
  @$core.override
  UnboundStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnboundStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnboundStatus>(create);
  static UnboundStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get registrationToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set registrationToken($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRegistrationToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegistrationToken() => $_clearField(1);
}

/// BindServiceRequest binds a service to the organization using a token.
class BindServiceRequest extends $pb.GeneratedMessage {
  factory BindServiceRequest({
    $core.String? registrationToken,
  }) {
    final result = create();
    if (registrationToken != null) result.registrationToken = registrationToken;
    return result;
  }

  BindServiceRequest._();

  factory BindServiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BindServiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BindServiceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'registrationToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindServiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindServiceRequest copyWith(void Function(BindServiceRequest) updates) =>
      super.copyWith((message) => updates(message as BindServiceRequest))
          as BindServiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BindServiceRequest create() => BindServiceRequest._();
  @$core.override
  BindServiceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BindServiceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BindServiceRequest>(create);
  static BindServiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get registrationToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set registrationToken($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRegistrationToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegistrationToken() => $_clearField(1);
}

enum BindServiceResponse_Result { service, error, notSet }

/// BindServiceResponse returns the bound service or an error.
class BindServiceResponse extends $pb.GeneratedMessage {
  factory BindServiceResponse({
    BoundService? service,
    $0.Error? error,
  }) {
    final result = create();
    if (service != null) result.service = service;
    if (error != null) result.error = error;
    return result;
  }

  BindServiceResponse._();

  factory BindServiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BindServiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, BindServiceResponse_Result>
      _BindServiceResponse_ResultByTag = {
    1: BindServiceResponse_Result.service,
    2: BindServiceResponse_Result.error,
    0: BindServiceResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BindServiceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<BoundService>(1, _omitFieldNames ? '' : 'service',
        subBuilder: BoundService.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindServiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindServiceResponse copyWith(void Function(BindServiceResponse) updates) =>
      super.copyWith((message) => updates(message as BindServiceResponse))
          as BindServiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BindServiceResponse create() => BindServiceResponse._();
  @$core.override
  BindServiceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BindServiceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BindServiceResponse>(create);
  static BindServiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  BindServiceResponse_Result whichResult() =>
      _BindServiceResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BoundService get service => $_getN(0);
  @$pb.TagNumber(1)
  set service(BoundService value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasService() => $_has(0);
  @$pb.TagNumber(1)
  void clearService() => $_clearField(1);
  @$pb.TagNumber(1)
  BoundService ensureService() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

/// BoundService contains info about the newly bound service.
class BoundService extends $pb.GeneratedMessage {
  factory BoundService({
    $core.String? serviceId,
    $core.String? serviceName,
    $core.Iterable<$1.ServiceType>? serviceTypes,
  }) {
    final result = create();
    if (serviceId != null) result.serviceId = serviceId;
    if (serviceName != null) result.serviceName = serviceName;
    if (serviceTypes != null) result.serviceTypes.addAll(serviceTypes);
    return result;
  }

  BoundService._();

  factory BoundService.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoundService.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoundService',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceId')
    ..aOS(2, _omitFieldNames ? '' : 'serviceName')
    ..pc<$1.ServiceType>(
        3, _omitFieldNames ? '' : 'serviceTypes', $pb.PbFieldType.KE,
        valueOf: $1.ServiceType.valueOf,
        enumValues: $1.ServiceType.values,
        defaultEnumValue: $1.ServiceType.SERVICE_TYPE_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundService clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundService copyWith(void Function(BoundService) updates) =>
      super.copyWith((message) => updates(message as BoundService))
          as BoundService;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoundService create() => BoundService._();
  @$core.override
  BoundService createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoundService getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BoundService>(create);
  static BoundService? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serviceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set serviceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServiceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearServiceName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$1.ServiceType> get serviceTypes => $_getList(2);
}

/// ListOrganizationServicesRequest requests all services for an organization.
/// Organization ID is extracted from the NATS subject.
class ListOrganizationServicesRequest extends $pb.GeneratedMessage {
  factory ListOrganizationServicesRequest() => create();

  ListOrganizationServicesRequest._();

  factory ListOrganizationServicesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListOrganizationServicesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListOrganizationServicesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationServicesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationServicesRequest copyWith(
          void Function(ListOrganizationServicesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListOrganizationServicesRequest))
          as ListOrganizationServicesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListOrganizationServicesRequest create() =>
      ListOrganizationServicesRequest._();
  @$core.override
  ListOrganizationServicesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListOrganizationServicesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListOrganizationServicesRequest>(
          create);
  static ListOrganizationServicesRequest? _defaultInstance;
}

enum ListOrganizationServicesResponse_Result { services, error, notSet }

/// ListOrganizationServicesResponse returns the services or an error.
class ListOrganizationServicesResponse extends $pb.GeneratedMessage {
  factory ListOrganizationServicesResponse({
    OrganizationServicesList? services,
    $0.Error? error,
  }) {
    final result = create();
    if (services != null) result.services = services;
    if (error != null) result.error = error;
    return result;
  }

  ListOrganizationServicesResponse._();

  factory ListOrganizationServicesResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListOrganizationServicesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListOrganizationServicesResponse_Result>
      _ListOrganizationServicesResponse_ResultByTag = {
    1: ListOrganizationServicesResponse_Result.services,
    2: ListOrganizationServicesResponse_Result.error,
    0: ListOrganizationServicesResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListOrganizationServicesResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OrganizationServicesList>(1, _omitFieldNames ? '' : 'services',
        subBuilder: OrganizationServicesList.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationServicesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListOrganizationServicesResponse copyWith(
          void Function(ListOrganizationServicesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListOrganizationServicesResponse))
          as ListOrganizationServicesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListOrganizationServicesResponse create() =>
      ListOrganizationServicesResponse._();
  @$core.override
  ListOrganizationServicesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListOrganizationServicesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListOrganizationServicesResponse>(
          create);
  static ListOrganizationServicesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListOrganizationServicesResponse_Result whichResult() =>
      _ListOrganizationServicesResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OrganizationServicesList get services => $_getN(0);
  @$pb.TagNumber(1)
  set services(OrganizationServicesList value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServices() => $_has(0);
  @$pb.TagNumber(1)
  void clearServices() => $_clearField(1);
  @$pb.TagNumber(1)
  OrganizationServicesList ensureServices() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

/// OrganizationServicesList contains the list of services.
class OrganizationServicesList extends $pb.GeneratedMessage {
  factory OrganizationServicesList({
    $core.Iterable<$1.Service>? services,
  }) {
    final result = create();
    if (services != null) result.services.addAll(services);
    return result;
  }

  OrganizationServicesList._();

  factory OrganizationServicesList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrganizationServicesList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrganizationServicesList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..pPM<$1.Service>(1, _omitFieldNames ? '' : 'services',
        subBuilder: $1.Service.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationServicesList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationServicesList copyWith(
          void Function(OrganizationServicesList) updates) =>
      super.copyWith((message) => updates(message as OrganizationServicesList))
          as OrganizationServicesList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrganizationServicesList create() => OrganizationServicesList._();
  @$core.override
  OrganizationServicesList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrganizationServicesList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrganizationServicesList>(create);
  static OrganizationServicesList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.Service> get services => $_getList(0);
}

/// ServiceBoundNotification is published when binding completes.
class ServiceBoundNotification extends $pb.GeneratedMessage {
  factory ServiceBoundNotification({
    $core.String? organizationId,
    $core.String? organizationName,
  }) {
    final result = create();
    if (organizationId != null) result.organizationId = organizationId;
    if (organizationName != null) result.organizationName = organizationName;
    return result;
  }

  ServiceBoundNotification._();

  factory ServiceBoundNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceBoundNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceBoundNotification',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'organizationId')
    ..aOS(2, _omitFieldNames ? '' : 'organizationName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceBoundNotification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceBoundNotification copyWith(
          void Function(ServiceBoundNotification) updates) =>
      super.copyWith((message) => updates(message as ServiceBoundNotification))
          as ServiceBoundNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceBoundNotification create() => ServiceBoundNotification._();
  @$core.override
  ServiceBoundNotification createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceBoundNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceBoundNotification>(create);
  static ServiceBoundNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get organizationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set organizationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOrganizationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrganizationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get organizationName => $_getSZ(1);
  @$pb.TagNumber(2)
  set organizationName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrganizationName() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrganizationName() => $_clearField(2);
}

/// UpdateServiceRequest updates a service's metadata.
/// Service must be bound to the organization specified in the NATS subject.
class UpdateServiceRequest extends $pb.GeneratedMessage {
  factory UpdateServiceRequest({
    $core.String? serviceId,
    $core.String? name,
  }) {
    final result = create();
    if (serviceId != null) result.serviceId = serviceId;
    if (name != null) result.name = name;
    return result;
  }

  UpdateServiceRequest._();

  factory UpdateServiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateServiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateServiceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateServiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateServiceRequest copyWith(void Function(UpdateServiceRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateServiceRequest))
          as UpdateServiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateServiceRequest create() => UpdateServiceRequest._();
  @$core.override
  UpdateServiceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateServiceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateServiceRequest>(create);
  static UpdateServiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

enum UpdateServiceResponse_Result { service, error, notSet }

/// UpdateServiceResponse returns the updated service or an error.
class UpdateServiceResponse extends $pb.GeneratedMessage {
  factory UpdateServiceResponse({
    $1.Service? service,
    $0.Error? error,
  }) {
    final result = create();
    if (service != null) result.service = service;
    if (error != null) result.error = error;
    return result;
  }

  UpdateServiceResponse._();

  factory UpdateServiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateServiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateServiceResponse_Result>
      _UpdateServiceResponse_ResultByTag = {
    1: UpdateServiceResponse_Result.service,
    2: UpdateServiceResponse_Result.error,
    0: UpdateServiceResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateServiceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.Service>(1, _omitFieldNames ? '' : 'service',
        subBuilder: $1.Service.create)
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateServiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateServiceResponse copyWith(
          void Function(UpdateServiceResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateServiceResponse))
          as UpdateServiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateServiceResponse create() => UpdateServiceResponse._();
  @$core.override
  UpdateServiceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateServiceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateServiceResponse>(create);
  static UpdateServiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UpdateServiceResponse_Result whichResult() =>
      _UpdateServiceResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.Service get service => $_getN(0);
  @$pb.TagNumber(1)
  set service($1.Service value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasService() => $_has(0);
  @$pb.TagNumber(1)
  void clearService() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Service ensureService() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

/// UnbindServiceRequest removes a service from the organization.
/// Service must be bound to the organization specified in the NATS subject.
class UnbindServiceRequest extends $pb.GeneratedMessage {
  factory UnbindServiceRequest({
    $core.String? serviceId,
  }) {
    final result = create();
    if (serviceId != null) result.serviceId = serviceId;
    return result;
  }

  UnbindServiceRequest._();

  factory UnbindServiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnbindServiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnbindServiceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbindServiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbindServiceRequest copyWith(void Function(UnbindServiceRequest) updates) =>
      super.copyWith((message) => updates(message as UnbindServiceRequest))
          as UnbindServiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnbindServiceRequest create() => UnbindServiceRequest._();
  @$core.override
  UnbindServiceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnbindServiceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnbindServiceRequest>(create);
  static UnbindServiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceId() => $_clearField(1);
}

enum UnbindServiceResponse_Result { success, error, notSet }

/// UnbindServiceResponse returns success or an error.
class UnbindServiceResponse extends $pb.GeneratedMessage {
  factory UnbindServiceResponse({
    $core.bool? success,
    $0.Error? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  UnbindServiceResponse._();

  factory UnbindServiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnbindServiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UnbindServiceResponse_Result>
      _UnbindServiceResponse_ResultByTag = {
    1: UnbindServiceResponse_Result.success,
    2: UnbindServiceResponse_Result.error,
    0: UnbindServiceResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnbindServiceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<$0.Error>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $0.Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbindServiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbindServiceResponse copyWith(
          void Function(UnbindServiceResponse) updates) =>
      super.copyWith((message) => updates(message as UnbindServiceResponse))
          as UnbindServiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnbindServiceResponse create() => UnbindServiceResponse._();
  @$core.override
  UnbindServiceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnbindServiceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnbindServiceResponse>(create);
  static UnbindServiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UnbindServiceResponse_Result whichResult() =>
      _UnbindServiceResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Error ensureError() => $_ensure(1);
}

/// ServiceHeartbeatRequest updates the service's state to online.
/// Service ID is extracted from the NATS subject.
class ServiceHeartbeatRequest extends $pb.GeneratedMessage {
  factory ServiceHeartbeatRequest() => create();

  ServiceHeartbeatRequest._();

  factory ServiceHeartbeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceHeartbeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceHeartbeatRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceHeartbeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceHeartbeatRequest copyWith(
          void Function(ServiceHeartbeatRequest) updates) =>
      super.copyWith((message) => updates(message as ServiceHeartbeatRequest))
          as ServiceHeartbeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceHeartbeatRequest create() => ServiceHeartbeatRequest._();
  @$core.override
  ServiceHeartbeatRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceHeartbeatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceHeartbeatRequest>(create);
  static ServiceHeartbeatRequest? _defaultInstance;
}

/// ServiceShutdownRequest indicates the service is going offline.
/// Service ID is extracted from the NATS subject.
class ServiceShutdownRequest extends $pb.GeneratedMessage {
  factory ServiceShutdownRequest() => create();

  ServiceShutdownRequest._();

  factory ServiceShutdownRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceShutdownRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceShutdownRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'typewriter.api.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceShutdownRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceShutdownRequest copyWith(
          void Function(ServiceShutdownRequest) updates) =>
      super.copyWith((message) => updates(message as ServiceShutdownRequest))
          as ServiceShutdownRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceShutdownRequest create() => ServiceShutdownRequest._();
  @$core.override
  ServiceShutdownRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceShutdownRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceShutdownRequest>(create);
  static ServiceShutdownRequest? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
