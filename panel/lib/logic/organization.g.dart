// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationData _$OrganizationDataFromJson(Map<String, dynamic> json) =>
    _OrganizationData(
      name: json['name'] as String,
      id: json['id'] as String,
      iconUrl: json['iconUrl'] as String?,
    );

Map<String, dynamic> _$OrganizationDataToJson(_OrganizationData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'iconUrl': instance.iconUrl,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Organizations)
const organizationsProvider = OrganizationsProvider._();

final class OrganizationsProvider
    extends $AsyncNotifierProvider<Organizations, List<OrganizationData>> {
  const OrganizationsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'organizationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$organizationsHash();

  @$internal
  @override
  Organizations create() => Organizations();

  @$internal
  @override
  $AsyncNotifierProviderElement<Organizations, List<OrganizationData>>
      $createElement($ProviderPointer pointer) =>
          $AsyncNotifierProviderElement(pointer);
}

String _$organizationsHash() => r'c7888d4baaf55f73c6535389e4a266080fc09619';

abstract class _$Organizations extends $AsyncNotifier<List<OrganizationData>> {
  FutureOr<List<OrganizationData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<OrganizationData>>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<OrganizationData>>>,
        AsyncValue<List<OrganizationData>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(organizationId)
const organizationIdProvider = OrganizationIdProvider._();

final class OrganizationIdProvider extends $FunctionalProvider<String?, String?>
    with $Provider<String?> {
  const OrganizationIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'organizationIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$organizationIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return organizationId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<String?>(value),
    );
  }
}

String _$organizationIdHash() => r'013e2c6e1ab3e419defc8d87912ade098515dd7b';

@ProviderFor(Organization)
const organizationProvider = OrganizationProvider._();

final class OrganizationProvider
    extends $AsyncNotifierProvider<Organization, OrganizationData?> {
  const OrganizationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'organizationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$organizationHash();

  @$internal
  @override
  Organization create() => Organization();

  @$internal
  @override
  $AsyncNotifierProviderElement<Organization, OrganizationData?> $createElement(
          $ProviderPointer pointer) =>
      $AsyncNotifierProviderElement(pointer);
}

String _$organizationHash() => r'9fe52811cf7445c0cebdc75a52997745b10b5895';

abstract class _$Organization extends $AsyncNotifier<OrganizationData?> {
  FutureOr<OrganizationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<OrganizationData?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<OrganizationData?>>,
        AsyncValue<OrganizationData?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
