// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the list of available roles in the current organization.

@ProviderFor(OrganizationRoles)
const organizationRolesProvider = OrganizationRolesProvider._();

/// Provider for the list of available roles in the current organization.
final class OrganizationRolesProvider
    extends $AsyncNotifierProvider<OrganizationRoles, List<MemberRole>> {
  /// Provider for the list of available roles in the current organization.
  const OrganizationRolesProvider._()
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

String _$organizationRolesHash() => r'7348a8a6afb01129e836abff6bed19c2164b6ec7';

/// Provider for the list of available roles in the current organization.

abstract class _$OrganizationRoles extends $AsyncNotifier<List<MemberRole>> {
  FutureOr<List<MemberRole>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<MemberRole>>, List<MemberRole>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MemberRole>>, List<MemberRole>>,
              AsyncValue<List<MemberRole>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for the list of members in the current organization.

@ProviderFor(OrganizationMembers)
const organizationMembersProvider = OrganizationMembersProvider._();

/// Provider for the list of members in the current organization.
final class OrganizationMembersProvider
    extends
        $AsyncNotifierProvider<OrganizationMembers, List<OrganizationMember>> {
  /// Provider for the list of members in the current organization.
  const OrganizationMembersProvider._()
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
    r'e2d8c7abb90b9e72d56560a7bac88bb79c44aeea';

/// Provider for the list of members in the current organization.

abstract class _$OrganizationMembers
    extends $AsyncNotifier<List<OrganizationMember>> {
  FutureOr<List<OrganizationMember>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}

/// Provider for the list of pending join requests to the current organization.

@ProviderFor(OrganizationJoinRequests)
const organizationJoinRequestsProvider = OrganizationJoinRequestsProvider._();

/// Provider for the list of pending join requests to the current organization.
final class OrganizationJoinRequestsProvider
    extends
        $AsyncNotifierProvider<OrganizationJoinRequests, List<JoinRequest>> {
  /// Provider for the list of pending join requests to the current organization.
  const OrganizationJoinRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationJoinRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationJoinRequestsHash();

  @$internal
  @override
  OrganizationJoinRequests create() => OrganizationJoinRequests();
}

String _$organizationJoinRequestsHash() =>
    r'fcf17401855f85ccbb49e386ca0ee7803cbe2edb';

/// Provider for the list of pending join requests to the current organization.

abstract class _$OrganizationJoinRequests
    extends $AsyncNotifier<List<JoinRequest>> {
  FutureOr<List<JoinRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<JoinRequest>>, List<JoinRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JoinRequest>>, List<JoinRequest>>,
              AsyncValue<List<JoinRequest>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for the count of pending join requests.

@ProviderFor(joinRequestCount)
const joinRequestCountProvider = JoinRequestCountProvider._();

/// Provider for the count of pending join requests.

final class JoinRequestCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for the count of pending join requests.
  const JoinRequestCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRequestCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRequestCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return joinRequestCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$joinRequestCountHash() => r'297dcfa4f5bd0b642bcc4f3b163ee3ac79fac7bd';
