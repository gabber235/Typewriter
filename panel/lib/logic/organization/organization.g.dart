// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
}

String _$organizationsHash() => r'3e85562e86814e3699cfdaeea1b927998a69dee0';

abstract class _$Organizations extends $AsyncNotifier<List<OrganizationData>> {
  FutureOr<List<OrganizationData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}

@ProviderFor(organizationId)
const organizationIdProvider = OrganizationIdProvider._();

final class OrganizationIdProvider
    extends $FunctionalProvider<String?, String?, String?>
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
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$organizationIdHash() => r'f6f5c4b016f460787d6e45f57e4728b708016496';

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
}

String _$organizationHash() => r'922d220f3bd8ca2abbccb4c9c01606b3d9415f23';

abstract class _$Organization extends $AsyncNotifier<OrganizationData?> {
  FutureOr<OrganizationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}
