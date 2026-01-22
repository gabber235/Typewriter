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

/// ServiceType represents the type of service (engine or realm).
class ServiceType extends $pb.ProtobufEnum {
  /// Unspecified service type (default value).
  static const ServiceType SERVICE_TYPE_UNSPECIFIED =
      ServiceType._(0, _omitEnumNames ? '' : 'SERVICE_TYPE_UNSPECIFIED');

  /// Engine service type.
  static const ServiceType SERVICE_TYPE_ENGINE =
      ServiceType._(1, _omitEnumNames ? '' : 'SERVICE_TYPE_ENGINE');

  /// Realm service type.
  static const ServiceType SERVICE_TYPE_REALM =
      ServiceType._(2, _omitEnumNames ? '' : 'SERVICE_TYPE_REALM');

  static const $core.List<ServiceType> values = <ServiceType>[
    SERVICE_TYPE_UNSPECIFIED,
    SERVICE_TYPE_ENGINE,
    SERVICE_TYPE_REALM,
  ];

  static final $core.List<ServiceType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ServiceType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ServiceType._(super.value, super.name);
}

/// ServiceStatus represents the current online/offline status of a service.
class ServiceStatus extends $pb.ProtobufEnum {
  /// Unspecified status (service has never reported).
  static const ServiceStatus SERVICE_STATUS_UNSPECIFIED =
      ServiceStatus._(0, _omitEnumNames ? '' : 'SERVICE_STATUS_UNSPECIFIED');

  /// Service is online and responding to heartbeats.
  static const ServiceStatus SERVICE_STATUS_ONLINE =
      ServiceStatus._(1, _omitEnumNames ? '' : 'SERVICE_STATUS_ONLINE');

  /// Service has explicitly shut down.
  static const ServiceStatus SERVICE_STATUS_OFFLINE =
      ServiceStatus._(2, _omitEnumNames ? '' : 'SERVICE_STATUS_OFFLINE');

  static const $core.List<ServiceStatus> values = <ServiceStatus>[
    SERVICE_STATUS_UNSPECIFIED,
    SERVICE_STATUS_ONLINE,
    SERVICE_STATUS_OFFLINE,
  ];

  static final $core.List<ServiceStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ServiceStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ServiceStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
