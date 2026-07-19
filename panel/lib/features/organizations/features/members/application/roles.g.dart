// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roles.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrganizationRoles)
final organizationRolesProvider = OrganizationRolesProvider._();

final class OrganizationRolesProvider
    extends $StreamNotifierProvider<OrganizationRoles, List<OrganizationRole>> {
  OrganizationRolesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationRolesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationRolesHash();

  @$internal
  @override
  OrganizationRoles create() => OrganizationRoles();
}

String _$organizationRolesHash() => r'4c3942855503b8cbe063448ba83002086d65623d';

abstract class _$OrganizationRoles
    extends $StreamNotifier<List<OrganizationRole>> {
  Stream<List<OrganizationRole>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<OrganizationRole>>, List<OrganizationRole>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationRole>>,
                List<OrganizationRole>
              >,
              AsyncValue<List<OrganizationRole>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
