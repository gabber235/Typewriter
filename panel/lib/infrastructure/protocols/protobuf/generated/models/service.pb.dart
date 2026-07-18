// This is a generated file - do not edit.
//
// Generated from models/service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'service.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'service.pbenum.dart';

/// ServiceState contains the current status and last seen timestamp.
class ServiceState extends $pb.GeneratedMessage {
  factory ServiceState({
    ServiceStatus? status,
    $0.Timestamp? lastSeen,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (lastSeen != null) result.lastSeen = lastSeen;
    return result;
  }

  ServiceState._();

  factory ServiceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aE<ServiceStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: ServiceStatus.values)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'lastSeen',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceState copyWith(void Function(ServiceState) updates) =>
      super.copyWith((message) => updates(message as ServiceState))
          as ServiceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceState create() => ServiceState._();
  @$core.override
  ServiceState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceState>(create);
  static ServiceState? _defaultInstance;

  /// Current status of the service.
  @$pb.TagNumber(1)
  ServiceStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ServiceStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// Timestamp when the service was last seen.
  @$pb.TagNumber(2)
  $0.Timestamp get lastSeen => $_getN(1);
  @$pb.TagNumber(2)
  set lastSeen($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLastSeen() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastSeen() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureLastSeen() => $_ensure(1);
}

/// ServiceMetadata contains version and other metadata about a service.
class ServiceMetadata extends $pb.GeneratedMessage {
  factory ServiceMetadata({
    $core.String? engineVersion,
    $core.String? realmVersion,
  }) {
    final result = create();
    if (engineVersion != null) result.engineVersion = engineVersion;
    if (realmVersion != null) result.realmVersion = realmVersion;
    return result;
  }

  ServiceMetadata._();

  factory ServiceMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceMetadata',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'engineVersion')
    ..aOS(2, _omitFieldNames ? '' : 'realmVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceMetadata copyWith(void Function(ServiceMetadata) updates) =>
      super.copyWith((message) => updates(message as ServiceMetadata))
          as ServiceMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceMetadata create() => ServiceMetadata._();
  @$core.override
  ServiceMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceMetadata>(create);
  static ServiceMetadata? _defaultInstance;

  /// Version of the engine (if applicable).
  @$pb.TagNumber(1)
  $core.String get engineVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set engineVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEngineVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearEngineVersion() => $_clearField(1);

  /// Version of the realm (if applicable).
  @$pb.TagNumber(2)
  $core.String get realmVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set realmVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRealmVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearRealmVersion() => $_clearField(2);
}

/// Service represents a service identity stored in SurrealDB.
class Service extends $pb.GeneratedMessage {
  factory Service({
    $core.String? serviceId,
    $core.String? name,
    $core.Iterable<ServiceType>? serviceTypes,
    $0.Timestamp? createdAt,
    ServiceState? state,
    ServiceMetadata? metadata,
    $core.String? organizationId,
  }) {
    final result = create();
    if (serviceId != null) result.serviceId = serviceId;
    if (name != null) result.name = name;
    if (serviceTypes != null) result.serviceTypes.addAll(serviceTypes);
    if (createdAt != null) result.createdAt = createdAt;
    if (state != null) result.state = state;
    if (metadata != null) result.metadata = metadata;
    if (organizationId != null) result.organizationId = organizationId;
    return result;
  }

  Service._();

  factory Service.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Service.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Service',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pc<ServiceType>(
        3, _omitFieldNames ? '' : 'serviceTypes', $pb.PbFieldType.KE,
        valueOf: ServiceType.valueOf,
        enumValues: ServiceType.values,
        defaultEnumValue: ServiceType.SERVICE_TYPE_UNSPECIFIED)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<ServiceState>(5, _omitFieldNames ? '' : 'state',
        subBuilder: ServiceState.create)
    ..aOM<ServiceMetadata>(6, _omitFieldNames ? '' : 'metadata',
        subBuilder: ServiceMetadata.create)
    ..aOS(7, _omitFieldNames ? '' : 'organizationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Service clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Service copyWith(void Function(Service) updates) =>
      super.copyWith((message) => updates(message as Service)) as Service;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Service create() => Service._();
  @$core.override
  Service createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Service getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Service>(create);
  static Service? _defaultInstance;

  /// Service identifier (authentik_user_id as record ID).
  @$pb.TagNumber(1)
  $core.String get serviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceId() => $_clearField(1);

  /// Name of the service.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// List of service types (engine and/or realm).
  @$pb.TagNumber(3)
  $pb.PbList<ServiceType> get serviceTypes => $_getList(2);

  /// Timestamp when the service was created.
  @$pb.TagNumber(4)
  $0.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureCreatedAt() => $_ensure(3);

  /// Current state of the service (status and last seen).
  @$pb.TagNumber(5)
  ServiceState get state => $_getN(4);
  @$pb.TagNumber(5)
  set state(ServiceState value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasState() => $_has(4);
  @$pb.TagNumber(5)
  void clearState() => $_clearField(5);
  @$pb.TagNumber(5)
  ServiceState ensureState() => $_ensure(4);

  /// Metadata about the service.
  @$pb.TagNumber(6)
  ServiceMetadata get metadata => $_getN(5);
  @$pb.TagNumber(6)
  set metadata(ServiceMetadata value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadata() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetadata() => $_clearField(6);
  @$pb.TagNumber(6)
  ServiceMetadata ensureMetadata() => $_ensure(5);

  /// Organization this service is bound to (optional).
  @$pb.TagNumber(7)
  $core.String get organizationId => $_getSZ(6);
  @$pb.TagNumber(7)
  set organizationId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOrganizationId() => $_has(6);
  @$pb.TagNumber(7)
  void clearOrganizationId() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
