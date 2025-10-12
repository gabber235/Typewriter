// This is a generated file - do not edit.
//
// Generated from models/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/duration.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Permission extends $pb.GeneratedMessage {
  factory Permission({
    $core.Iterable<$core.String>? allow,
    $core.Iterable<$core.String>? deny,
  }) {
    final result = create();
    if (allow != null) result.allow.addAll(allow);
    if (deny != null) result.deny.addAll(deny);
    return result;
  }

  Permission._();

  factory Permission.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Permission.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Permission',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'allow')
    ..pPS(2, _omitFieldNames ? '' : 'deny')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permission clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permission copyWith(void Function(Permission) updates) =>
      super.copyWith((message) => updates(message as Permission)) as Permission;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Permission create() => Permission._();
  @$core.override
  Permission createEmptyInstance() => create();
  static $pb.PbList<Permission> createRepeated() => $pb.PbList<Permission>();
  @$core.pragma('dart2js:noInline')
  static Permission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Permission>(create);
  static Permission? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get allow => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get deny => $_getList(1);
}

class ResponsePermission extends $pb.GeneratedMessage {
  factory ResponsePermission({
    $core.int? maxMessages,
    $0.Duration? ttl,
  }) {
    final result = create();
    if (maxMessages != null) result.maxMessages = maxMessages;
    if (ttl != null) result.ttl = ttl;
    return result;
  }

  ResponsePermission._();

  factory ResponsePermission.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponsePermission.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponsePermission',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'maxMessages')
    ..aOM<$0.Duration>(2, _omitFieldNames ? '' : 'ttl',
        subBuilder: $0.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponsePermission clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponsePermission copyWith(void Function(ResponsePermission) updates) =>
      super.copyWith((message) => updates(message as ResponsePermission))
          as ResponsePermission;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponsePermission create() => ResponsePermission._();
  @$core.override
  ResponsePermission createEmptyInstance() => create();
  static $pb.PbList<ResponsePermission> createRepeated() =>
      $pb.PbList<ResponsePermission>();
  @$core.pragma('dart2js:noInline')
  static ResponsePermission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponsePermission>(create);
  static ResponsePermission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get maxMessages => $_getIZ(0);
  @$pb.TagNumber(1)
  set maxMessages($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMaxMessages() => $_has(0);
  @$pb.TagNumber(1)
  void clearMaxMessages() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Duration get ttl => $_getN(1);
  @$pb.TagNumber(2)
  set ttl($0.Duration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTtl() => $_has(1);
  @$pb.TagNumber(2)
  void clearTtl() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Duration ensureTtl() => $_ensure(1);
}

class Permissions extends $pb.GeneratedMessage {
  factory Permissions({
    Permission? publish,
    Permission? subscribe,
    ResponsePermission? resp,
  }) {
    final result = create();
    if (publish != null) result.publish = publish;
    if (subscribe != null) result.subscribe = subscribe;
    if (resp != null) result.resp = resp;
    return result;
  }

  Permissions._();

  factory Permissions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Permissions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Permissions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'typewriter.models.v1'),
      createEmptyInstance: create)
    ..aOM<Permission>(1, _omitFieldNames ? '' : 'publish',
        subBuilder: Permission.create)
    ..aOM<Permission>(2, _omitFieldNames ? '' : 'subscribe',
        subBuilder: Permission.create)
    ..aOM<ResponsePermission>(3, _omitFieldNames ? '' : 'resp',
        subBuilder: ResponsePermission.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permissions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permissions copyWith(void Function(Permissions) updates) =>
      super.copyWith((message) => updates(message as Permissions))
          as Permissions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Permissions create() => Permissions._();
  @$core.override
  Permissions createEmptyInstance() => create();
  static $pb.PbList<Permissions> createRepeated() => $pb.PbList<Permissions>();
  @$core.pragma('dart2js:noInline')
  static Permissions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Permissions>(create);
  static Permissions? _defaultInstance;

  @$pb.TagNumber(1)
  Permission get publish => $_getN(0);
  @$pb.TagNumber(1)
  set publish(Permission value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPublish() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublish() => $_clearField(1);
  @$pb.TagNumber(1)
  Permission ensurePublish() => $_ensure(0);

  @$pb.TagNumber(2)
  Permission get subscribe => $_getN(1);
  @$pb.TagNumber(2)
  set subscribe(Permission value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscribe() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscribe() => $_clearField(2);
  @$pb.TagNumber(2)
  Permission ensureSubscribe() => $_ensure(1);

  @$pb.TagNumber(3)
  ResponsePermission get resp => $_getN(2);
  @$pb.TagNumber(3)
  set resp(ResponsePermission value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResp() => $_has(2);
  @$pb.TagNumber(3)
  void clearResp() => $_clearField(3);
  @$pb.TagNumber(3)
  ResponsePermission ensureResp() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
