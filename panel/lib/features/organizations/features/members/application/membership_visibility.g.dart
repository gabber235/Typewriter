// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'membership_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pendingMembershipRemovals)
final pendingMembershipRemovalsProvider = PendingMembershipRemovalsProvider._();

final class PendingMembershipRemovalsProvider
    extends
        $FunctionalProvider<
          Set<(MembershipRemovalKind, skir.RecordId)>,
          Set<(MembershipRemovalKind, skir.RecordId)>,
          Set<(MembershipRemovalKind, skir.RecordId)>
        >
    with $Provider<Set<(MembershipRemovalKind, skir.RecordId)>> {
  PendingMembershipRemovalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMembershipRemovalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMembershipRemovalsHash();

  @$internal
  @override
  $ProviderElement<Set<(MembershipRemovalKind, skir.RecordId)>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Set<(MembershipRemovalKind, skir.RecordId)> create(Ref ref) {
    return pendingMembershipRemovals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Set<(MembershipRemovalKind, skir.RecordId)> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Set<(MembershipRemovalKind, skir.RecordId)>>(
            value,
          ),
    );
  }
}

String _$pendingMembershipRemovalsHash() =>
    r'530dd3ec6ba6ec8da8749a95b0a1007523c295b1';

@ProviderFor(membershipDisplayTime)
final membershipDisplayTimeProvider = MembershipDisplayTimeProvider._();

final class MembershipDisplayTimeProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  MembershipDisplayTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipDisplayTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipDisplayTimeHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return membershipDisplayTime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$membershipDisplayTimeHash() =>
    r'd23c285f05966d93ad41e67221d9ad6c32a83cbd';

@ProviderFor(visibleOrganizationJoinRequests)
final visibleOrganizationJoinRequestsProvider =
    VisibleOrganizationJoinRequestsProvider._();

final class VisibleOrganizationJoinRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrganizationJoinRequest>>,
          AsyncValue<List<OrganizationJoinRequest>>,
          AsyncValue<List<OrganizationJoinRequest>>
        >
    with $Provider<AsyncValue<List<OrganizationJoinRequest>>> {
  VisibleOrganizationJoinRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleOrganizationJoinRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleOrganizationJoinRequestsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<OrganizationJoinRequest>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<OrganizationJoinRequest>> create(Ref ref) {
    return visibleOrganizationJoinRequests(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<OrganizationJoinRequest>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<OrganizationJoinRequest>>>(value),
    );
  }
}

String _$visibleOrganizationJoinRequestsHash() =>
    r'f453ec6ca2c3c2c6cbaaeae0389a59f9c46e0eec';

@ProviderFor(visibleOrganizationJoinCodes)
final visibleOrganizationJoinCodesProvider =
    VisibleOrganizationJoinCodesProvider._();

final class VisibleOrganizationJoinCodesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrganizationJoinCode>>,
          AsyncValue<List<OrganizationJoinCode>>,
          AsyncValue<List<OrganizationJoinCode>>
        >
    with $Provider<AsyncValue<List<OrganizationJoinCode>>> {
  VisibleOrganizationJoinCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleOrganizationJoinCodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleOrganizationJoinCodesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<OrganizationJoinCode>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<OrganizationJoinCode>> create(Ref ref) {
    return visibleOrganizationJoinCodes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<OrganizationJoinCode>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<OrganizationJoinCode>>>(value),
    );
  }
}

String _$visibleOrganizationJoinCodesHash() =>
    r'28ed25a8befd9be3594986146b32d6fa263e2fbd';
