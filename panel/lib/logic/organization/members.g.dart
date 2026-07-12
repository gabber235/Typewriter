// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the list of available roles in the current organization.

@ProviderFor(OrganizationRoles)
final organizationRolesProvider = OrganizationRolesProvider._();

/// Provider for the list of available roles in the current organization.
final class OrganizationRolesProvider
    extends $StreamNotifierProvider<OrganizationRoles, List<OrganizationRole>> {
  /// Provider for the list of available roles in the current organization.
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

String _$organizationRolesHash() => r'9f54743a71574521e4c15acba15c3116952c1ab0';

/// Provider for the list of available roles in the current organization.

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

/// Provider for the list of members in the current organization.

@ProviderFor(OrganizationMembers)
final organizationMembersProvider = OrganizationMembersProvider._();

/// Provider for the list of members in the current organization.
final class OrganizationMembersProvider
    extends
        $StreamNotifierProvider<OrganizationMembers, List<OrganizationMember>> {
  /// Provider for the list of members in the current organization.
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
    r'b874d5df7ae66608d78f11ae0afe86742559d7a0';

/// Provider for the list of members in the current organization.

abstract class _$OrganizationMembers
    extends $StreamNotifier<List<OrganizationMember>> {
  Stream<List<OrganizationMember>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

/// Provider for the list of pending join requests to the current organization.

@ProviderFor(OrganizationJoinRequests)
final organizationJoinRequestsProvider = OrganizationJoinRequestsProvider._();

/// Provider for the list of pending join requests to the current organization.
final class OrganizationJoinRequestsProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinRequests,
          List<OrganizationJoinRequest>
        > {
  /// Provider for the list of pending join requests to the current organization.
  OrganizationJoinRequestsProvider._()
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
    r'68dfd75bdd31a52609f658ba24f1efd1ae7ca579';

/// Provider for the list of pending join requests to the current organization.

abstract class _$OrganizationJoinRequests
    extends $StreamNotifier<List<OrganizationJoinRequest>> {
  Stream<List<OrganizationJoinRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationJoinRequest>>,
              List<OrganizationJoinRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationJoinRequest>>,
                List<OrganizationJoinRequest>
              >,
              AsyncValue<List<OrganizationJoinRequest>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for the count of pending join requests.

@ProviderFor(joinRequestCount)
final joinRequestCountProvider = JoinRequestCountProvider._();

/// Provider for the count of pending join requests.

final class JoinRequestCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for the count of pending join requests.
  JoinRequestCountProvider._()
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

/// Provider for the list of active join codes in the current organization.

@ProviderFor(OrganizationJoinCodes)
final organizationJoinCodesProvider = OrganizationJoinCodesProvider._();

/// Provider for the list of active join codes in the current organization.
final class OrganizationJoinCodesProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinCodes,
          List<OrganizationJoinCode>
        > {
  /// Provider for the list of active join codes in the current organization.
  OrganizationJoinCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationJoinCodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationJoinCodesHash();

  @$internal
  @override
  OrganizationJoinCodes create() => OrganizationJoinCodes();
}

String _$organizationJoinCodesHash() =>
    r'f7709b13da90b4a9ead50fc887756cb777b3d195';

/// Provider for the list of active join codes in the current organization.

abstract class _$OrganizationJoinCodes
    extends $StreamNotifier<List<OrganizationJoinCode>> {
  Stream<List<OrganizationJoinCode>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationJoinCode>>,
              List<OrganizationJoinCode>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationJoinCode>>,
                List<OrganizationJoinCode>
              >,
              AsyncValue<List<OrganizationJoinCode>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for the count of active join codes.

@ProviderFor(joinCodeCount)
final joinCodeCountProvider = JoinCodeCountProvider._();

/// Provider for the count of active join codes.

final class JoinCodeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for the count of active join codes.
  JoinCodeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinCodeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinCodeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return joinCodeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$joinCodeCountHash() => r'422bf73b9b48b40efcf2dc1e9e2cf897eddbbfbc';
