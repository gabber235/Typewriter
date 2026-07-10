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

String _$organizationsHash() => r'b7a4969b5dac94c0ec561713b5c0a426b07d7f10';

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

String _$organizationIdHash() => r'beb72fd1ea7bd0ac994e386364ac0b137ea7894c';

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

String _$organizationHash() => r'dfe22b8d23d08b288893031da09f417d6c587435';

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
