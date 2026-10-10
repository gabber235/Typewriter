// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'roles.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the role catalog for the selected organization.
///
/// Membership editors consume this catalog to render available choices and
/// the protected roles that must remain visible. Invalidating this provider
/// reloads the authoritative snapshot.

@ProviderFor(OrganizationRoles)
final organizationRolesProvider = OrganizationRolesProvider._();

/// Loads the role catalog for the selected organization.
///
/// Membership editors consume this catalog to render available choices and
/// the protected roles that must remain visible. Invalidating this provider
/// reloads the authoritative snapshot.
final class OrganizationRolesProvider
    extends $StreamNotifierProvider<OrganizationRoles, List<OrganizationRole>> {
  /// Loads the role catalog for the selected organization.
  ///
  /// Membership editors consume this catalog to render available choices and
  /// the protected roles that must remain visible. Invalidating this provider
  /// reloads the authoritative snapshot.
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

String _$organizationRolesHash() => r'90b0b0d4cbe491fab747a0f9cfce584ef8ce6973';

/// Loads the role catalog for the selected organization.
///
/// Membership editors consume this catalog to render available choices and
/// the protected roles that must remain visible. Invalidating this provider
/// reloads the authoritative snapshot.

abstract class _$OrganizationRoles
    extends $StreamNotifier<List<OrganizationRole>> {
  Stream<List<OrganizationRole>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
