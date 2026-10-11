// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.

@ProviderFor(OrganizationMembers)
final organizationMembersProvider = OrganizationMembersProvider._();

/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.
final class OrganizationMembersProvider
    extends
        $StreamNotifierProvider<OrganizationMembers, List<OrganizationMember>> {
  /// Owns the current organization's member projection.
  ///
  /// The provider starts with a snapshot, applies later sequenced changes, and
  /// invalidates itself when a sequence gap makes the local projection unsafe to
  /// trust. [MembershipResourceRepository] owns commands and feeds confirmed
  /// events through the same ordered projection path as broker events.
  OrganizationMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationMembersHash();

  @$internal
  @override
  OrganizationMembers create() => OrganizationMembers();
}

String _$organizationMembersHash() =>
    r'a664c438463dd1faed674379733b83ec0490a84a';

/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.

abstract class _$OrganizationMembers
    extends $StreamNotifier<List<OrganizationMember>> {
  Stream<List<OrganizationMember>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationMember>>,
              List<OrganizationMember>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationMember>>,
                List<OrganizationMember>
              >,
              AsyncValue<List<OrganizationMember>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
