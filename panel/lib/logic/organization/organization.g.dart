// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Organizations)
final organizationsProvider = OrganizationsProvider._();

final class OrganizationsProvider
    extends $StreamNotifierProvider<Organizations, List<OrganizationData>> {
  OrganizationsProvider._()
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
}

String _$organizationsHash() => r'70532d3d8bf2e84f3e0e0a1271ba785d2c6d74ca';

abstract class _$Organizations extends $StreamNotifier<List<OrganizationData>> {
  Stream<List<OrganizationData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<OrganizationData>>, List<OrganizationData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationData>>,
                List<OrganizationData>
              >,
              AsyncValue<List<OrganizationData>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(organizationId)
final organizationIdProvider = OrganizationIdProvider._();

final class OrganizationIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
  OrganizationIdProvider._()
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
  $ProviderElement<skir.RecordId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.RecordId? create(Ref ref) {
    return organizationId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.RecordId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.RecordId?>(value),
    );
  }
}

String _$organizationIdHash() => r'9902444ecead9e5ebb83f436a847d913ff97d987';

@ProviderFor(Organization)
final organizationProvider = OrganizationProvider._();

final class OrganizationProvider
    extends $AsyncNotifierProvider<Organization, OrganizationData?> {
  OrganizationProvider._()
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
}

String _$organizationHash() => r'76835916dc2ead497c5a1d5bae32c9daaa7614c2';

abstract class _$Organization extends $AsyncNotifier<OrganizationData?> {
  FutureOr<OrganizationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OrganizationData?>, OrganizationData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrganizationData?>, OrganizationData?>,
              AsyncValue<OrganizationData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
