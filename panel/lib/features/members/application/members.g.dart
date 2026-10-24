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
    r'2d054382fac1ba972de42de02d8ef429be8e1503';

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

/// The membership command owner for one organization in the current resource
/// session. Repeated reads share the repository and its mutation boundary.

@ProviderFor(membershipResourceRepository)
final membershipResourceRepositoryProvider =
    MembershipResourceRepositoryFamily._();

/// The membership command owner for one organization in the current resource
/// session. Repeated reads share the repository and its mutation boundary.

final class MembershipResourceRepositoryProvider
    extends
        $FunctionalProvider<
          MembershipResourceRepository,
          MembershipResourceRepository,
          MembershipResourceRepository
        >
    with $Provider<MembershipResourceRepository> {
  /// The membership command owner for one organization in the current resource
  /// session. Repeated reads share the repository and its mutation boundary.
  MembershipResourceRepositoryProvider._({
    required MembershipResourceRepositoryFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'membershipResourceRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membershipResourceRepositoryHash();

  @override
  String toString() {
    return r'membershipResourceRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MembershipResourceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MembershipResourceRepository create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return membershipResourceRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MembershipResourceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MembershipResourceRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipResourceRepositoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membershipResourceRepositoryHash() =>
    r'28218970dc353940ac8b2f89d9ba27efe1f00a1a';

/// The membership command owner for one organization in the current resource
/// session. Repeated reads share the repository and its mutation boundary.

final class MembershipResourceRepositoryFamily extends $Family
    with
        $FunctionalFamilyOverride<MembershipResourceRepository, skir.RecordId> {
  MembershipResourceRepositoryFamily._()
    : super(
        retry: null,
        name: r'membershipResourceRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The membership command owner for one organization in the current resource
  /// session. Repeated reads share the repository and its mutation boundary.

  MembershipResourceRepositoryProvider call(skir.RecordId organization) =>
      MembershipResourceRepositoryProvider._(
        argument: organization,
        from: this,
      );

  @override
  String toString() => r'membershipResourceRepositoryProvider';
}
