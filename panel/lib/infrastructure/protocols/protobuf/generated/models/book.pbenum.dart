// This is a generated file - do not edit.
//
// Generated from models/book.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PageType extends $pb.ProtobufEnum {
  static const PageType PAGE_TYPE_SEQUENCE =
      PageType._(0, _omitEnumNames ? '' : 'PAGE_TYPE_SEQUENCE');
  static const PageType PAGE_TYPE_STATIC =
      PageType._(1, _omitEnumNames ? '' : 'PAGE_TYPE_STATIC');
  static const PageType PAGE_TYPE_SCENE =
      PageType._(2, _omitEnumNames ? '' : 'PAGE_TYPE_SCENE');
  static const PageType PAGE_TYPE_MANIFEST =
      PageType._(3, _omitEnumNames ? '' : 'PAGE_TYPE_MANIFEST');

  static const $core.List<PageType> values = <PageType>[
    PAGE_TYPE_SEQUENCE,
    PAGE_TYPE_STATIC,
    PAGE_TYPE_SCENE,
    PAGE_TYPE_MANIFEST,
  ];

  static final $core.List<PageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
