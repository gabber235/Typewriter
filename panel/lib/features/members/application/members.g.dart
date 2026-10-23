// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
        $StreamNotifierProvider<
          OrganizationMembers,
          List<skir.OrganizationMember>
        > {
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
    r'72be67c0ca0420960849bc9b921c15c7796b7785';

/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.

abstract class _$OrganizationMembers
    extends $StreamNotifier<List<skir.OrganizationMember>> {
  Stream<List<skir.OrganizationMember>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<skir.OrganizationMember>>,
              List<skir.OrganizationMember>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<skir.OrganizationMember>>,
                List<skir.OrganizationMember>
              >,
              AsyncValue<List<skir.OrganizationMember>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
