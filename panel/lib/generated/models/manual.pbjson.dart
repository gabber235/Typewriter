// This is a generated file - do not edit.
//
// Generated from models/manual.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use platformConstraintTypeDescriptor instead')
const PlatformConstraintType$json = {
  '1': 'PlatformConstraintType',
  '2': [
    {'1': 'PLATFORM_CONSTRAINT_TYPE_VERSION', '2': 0},
  ],
};

/// Descriptor for `PlatformConstraintType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List platformConstraintTypeDescriptor =
    $convert.base64Decode(
        'ChZQbGF0Zm9ybUNvbnN0cmFpbnRUeXBlEiQKIFBMQVRGT1JNX0NPTlNUUkFJTlRfVFlQRV9WRV'
        'JTSU9OEAA=');

@$core.Deprecated('Use manualDescriptor instead')
const Manual$json = {
  '1': 'Manual',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'platforms',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.PlatformTarget',
      '10': 'platforms'
    },
    {
      '1': 'modules',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.ManualModuleReference',
      '10': 'modules'
    },
    {'1': 'auto_update', '3': 5, '4': 1, '5': 8, '10': 'autoUpdate'},
  ],
};

/// Descriptor for `Manual`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List manualDescriptor = $convert.base64Decode(
    'CgZNYW51YWwSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSQgoJcGxhdGZvcm'
    '1zGAMgAygLMiQudHlwZXdyaXRlci5tb2RlbHMudjEuUGxhdGZvcm1UYXJnZXRSCXBsYXRmb3Jt'
    'cxJFCgdtb2R1bGVzGAQgAygLMisudHlwZXdyaXRlci5tb2RlbHMudjEuTWFudWFsTW9kdWxlUm'
    'VmZXJlbmNlUgdtb2R1bGVzEh8KC2F1dG9fdXBkYXRlGAUgASgIUgphdXRvVXBkYXRl');

@$core.Deprecated('Use platformDescriptor instead')
const Platform$json = {
  '1': 'Platform',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'color',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Color',
      '10': 'color'
    },
    {
      '1': 'requirements',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.PlatformRequirement',
      '10': 'requirements'
    },
  ],
};

/// Descriptor for `Platform`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List platformDescriptor = $convert.base64Decode(
    'CghQbGF0Zm9ybRIOCgJpZBgBIAEoCVICaWQSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbG'
    'F5TmFtZRIxCgVjb2xvchgDIAEoCzIbLnR5cGV3cml0ZXIubW9kZWxzLnYxLkNvbG9yUgVjb2xv'
    'chJNCgxyZXF1aXJlbWVudHMYBCADKAsyKS50eXBld3JpdGVyLm1vZGVscy52MS5QbGF0Zm9ybV'
    'JlcXVpcmVtZW50UgxyZXF1aXJlbWVudHM=');

@$core.Deprecated('Use platformRequirementDescriptor instead')
const PlatformRequirement$json = {
  '1': 'PlatformRequirement',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.PlatformConstraintType',
      '10': 'type'
    },
  ],
};

/// Descriptor for `PlatformRequirement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List platformRequirementDescriptor = $convert.base64Decode(
    'ChNQbGF0Zm9ybVJlcXVpcmVtZW50EhIKBG5hbWUYASABKAlSBG5hbWUSQAoEdHlwZRgCIAEoDj'
    'IsLnR5cGV3cml0ZXIubW9kZWxzLnYxLlBsYXRmb3JtQ29uc3RyYWludFR5cGVSBHR5cGU=');

@$core.Deprecated('Use platformConstraintDescriptor instead')
const PlatformConstraint$json = {
  '1': 'PlatformConstraint',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.VersionConstraint',
      '9': 0,
      '10': 'version'
    },
  ],
  '8': [
    {'1': 'constraint'},
  ],
};

/// Descriptor for `PlatformConstraint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List platformConstraintDescriptor = $convert.base64Decode(
    'ChJQbGF0Zm9ybUNvbnN0cmFpbnQSQwoHdmVyc2lvbhgBIAEoCzInLnR5cGV3cml0ZXIubW9kZW'
    'xzLnYxLlZlcnNpb25Db25zdHJhaW50SABSB3ZlcnNpb25CDAoKY29uc3RyYWludA==');

@$core.Deprecated('Use versionConstraintDescriptor instead')
const VersionConstraint$json = {
  '1': 'VersionConstraint',
  '2': [
    {
      '1': 'versions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.Version',
      '10': 'versions'
    },
  ],
};

/// Descriptor for `VersionConstraint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionConstraintDescriptor = $convert.base64Decode(
    'ChFWZXJzaW9uQ29uc3RyYWludBI5Cgh2ZXJzaW9ucxgBIAMoCzIdLnR5cGV3cml0ZXIubW9kZW'
    'xzLnYxLlZlcnNpb25SCHZlcnNpb25z');

@$core.Deprecated('Use platformTargetDescriptor instead')
const PlatformTarget$json = {
  '1': 'PlatformTarget',
  '2': [
    {
      '1': 'platform',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Platform',
      '10': 'platform'
    },
    {
      '1': 'constraints',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.typewriter.models.v1.PlatformTarget.ConstraintsEntry',
      '10': 'constraints'
    },
  ],
  '3': [PlatformTarget_ConstraintsEntry$json],
};

@$core.Deprecated('Use platformTargetDescriptor instead')
const PlatformTarget_ConstraintsEntry$json = {
  '1': 'ConstraintsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.PlatformConstraint',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `PlatformTarget`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List platformTargetDescriptor = $convert.base64Decode(
    'Cg5QbGF0Zm9ybVRhcmdldBI6CghwbGF0Zm9ybRgBIAEoCzIeLnR5cGV3cml0ZXIubW9kZWxzLn'
    'YxLlBsYXRmb3JtUghwbGF0Zm9ybRJXCgtjb25zdHJhaW50cxgCIAMoCzI1LnR5cGV3cml0ZXIu'
    'bW9kZWxzLnYxLlBsYXRmb3JtVGFyZ2V0LkNvbnN0cmFpbnRzRW50cnlSC2NvbnN0cmFpbnRzGm'
    'gKEENvbnN0cmFpbnRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSPgoFdmFsdWUYAiABKAsyKC50'
    'eXBld3JpdGVyLm1vZGVscy52MS5QbGF0Zm9ybUNvbnN0cmFpbnRSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use manualModuleReferenceDescriptor instead')
const ManualModuleReference$json = {
  '1': 'ManualModuleReference',
  '2': [
    {'1': 'module_id', '3': 1, '4': 1, '5': 9, '10': 'moduleId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'version',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.typewriter.models.v1.Version',
      '10': 'version'
    },
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.typewriter.models.v1.ModuleType',
      '10': 'type'
    },
    {'1': 'dependencies', '3': 5, '4': 3, '5': 9, '10': 'dependencies'},
    {'1': 'dependents', '3': 6, '4': 3, '5': 9, '10': 'dependents'},
  ],
};

/// Descriptor for `ManualModuleReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List manualModuleReferenceDescriptor = $convert.base64Decode(
    'ChVNYW51YWxNb2R1bGVSZWZlcmVuY2USGwoJbW9kdWxlX2lkGAEgASgJUghtb2R1bGVJZBISCg'
    'RuYW1lGAIgASgJUgRuYW1lEjcKB3ZlcnNpb24YAyABKAsyHS50eXBld3JpdGVyLm1vZGVscy52'
    'MS5WZXJzaW9uUgd2ZXJzaW9uEjQKBHR5cGUYBCABKA4yIC50eXBld3JpdGVyLm1vZGVscy52MS'
    '5Nb2R1bGVUeXBlUgR0eXBlEiIKDGRlcGVuZGVuY2llcxgFIAMoCVIMZGVwZW5kZW5jaWVzEh4K'
    'CmRlcGVuZGVudHMYBiADKAlSCmRlcGVuZGVudHM=');
