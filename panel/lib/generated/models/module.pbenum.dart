// This is a generated file - do not edit.
//
// Generated from models/module.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ModuleType extends $pb.ProtobufEnum {
  static const ModuleType MODULE_TYPE_ENGINE =
      ModuleType._(0, _omitEnumNames ? '' : 'MODULE_TYPE_ENGINE');
  static const ModuleType MODULE_TYPE_EXTENSION =
      ModuleType._(1, _omitEnumNames ? '' : 'MODULE_TYPE_EXTENSION');

  static const $core.List<ModuleType> values = <ModuleType>[
    MODULE_TYPE_ENGINE,
    MODULE_TYPE_EXTENSION,
  ];

  static final $core.List<ModuleType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ModuleType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModuleType._(super.value, super.name);
}

class ModuleVersionState extends $pb.ProtobufEnum {
  static const ModuleVersionState MODULE_VERSION_STATE_DEVELOPING =
      ModuleVersionState._(
          0, _omitEnumNames ? '' : 'MODULE_VERSION_STATE_DEVELOPING');
  static const ModuleVersionState MODULE_VERSION_STATE_PUBLISHED =
      ModuleVersionState._(
          1, _omitEnumNames ? '' : 'MODULE_VERSION_STATE_PUBLISHED');
  static const ModuleVersionState MODULE_VERSION_STATE_YOINKED =
      ModuleVersionState._(
          2, _omitEnumNames ? '' : 'MODULE_VERSION_STATE_YOINKED');

  static const $core.List<ModuleVersionState> values = <ModuleVersionState>[
    MODULE_VERSION_STATE_DEVELOPING,
    MODULE_VERSION_STATE_PUBLISHED,
    MODULE_VERSION_STATE_YOINKED,
  ];

  static final $core.List<ModuleVersionState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ModuleVersionState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModuleVersionState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
