// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationData _$OrganizationDataFromJson(Map<String, dynamic> json) =>
    _OrganizationData(
      name: json['name'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$OrganizationDataToJson(_OrganizationData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$organizationHash() => r'72fa8c3fd1ac6ab56c22bc556b555765a884d8a7';

/// See also [Organization].
@ProviderFor(Organization)
final organizationProvider =
    AutoDisposeAsyncNotifierProvider<Organization, OrganizationData?>.internal(
  Organization.new,
  name: r'organizationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$organizationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Organization = AutoDisposeAsyncNotifier<OrganizationData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
