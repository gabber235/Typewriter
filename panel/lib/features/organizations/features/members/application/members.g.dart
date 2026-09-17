// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current organization's member projection and its mutations.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap or failed mutation makes the local
/// projection unsafe to trust. A successful mutation applies the returned
/// event, so consumers observe the same change stream as remote updates.

@ProviderFor(OrganizationMembers)
final organizationMembersProvider = OrganizationMembersProvider._();

/// Owns the current organization's member projection and its mutations.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap or failed mutation makes the local
/// projection unsafe to trust. A successful mutation applies the returned
/// event, so consumers observe the same change stream as remote updates.
final class OrganizationMembersProvider
    extends
        $StreamNotifierProvider<OrganizationMembers, List<OrganizationMember>> {
  /// Owns the current organization's member projection and its mutations.
  ///
  /// The provider starts with a snapshot, applies later sequenced changes, and
  /// invalidates itself when a sequence gap or failed mutation makes the local
  /// projection unsafe to trust. A successful mutation applies the returned
  /// event, so consumers observe the same change stream as remote updates.
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
    r'b11320b61873c77c35dfde83c55eef8ef609b4f4';

/// Owns the current organization's member projection and its mutations.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap or failed mutation makes the local
/// projection unsafe to trust. A successful mutation applies the returned
/// event, so consumers observe the same change stream as remote updates.

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
