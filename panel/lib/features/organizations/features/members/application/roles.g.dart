// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roles.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams the role catalog for the selected organization.
///
/// The initial list and later add, update, and remove messages are folded into
/// one provider value. Membership editors consume this catalog to render both
/// available choices and the protected roles that must remain visible.

@ProviderFor(OrganizationRoles)
final organizationRolesProvider = OrganizationRolesProvider._();

/// Streams the role catalog for the selected organization.
///
/// The initial list and later add, update, and remove messages are folded into
/// one provider value. Membership editors consume this catalog to render both
/// available choices and the protected roles that must remain visible.
final class OrganizationRolesProvider
    extends $StreamNotifierProvider<OrganizationRoles, List<OrganizationRole>> {
  /// Streams the role catalog for the selected organization.
  ///
  /// The initial list and later add, update, and remove messages are folded into
  /// one provider value. Membership editors consume this catalog to render both
  /// available choices and the protected roles that must remain visible.
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

String _$organizationRolesHash() => r'1a49470919cffe4d51184116252b0124a6614068';

/// Streams the role catalog for the selected organization.
///
/// The initial list and later add, update, and remove messages are folded into
/// one provider value. Membership editors consume this catalog to render both
/// available choices and the protected roles that must remain visible.

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
