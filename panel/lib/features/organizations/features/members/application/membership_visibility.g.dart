// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hides declined requests and revoked codes only while their commands send.
///
/// The canonical collections remain intact. When sending ends, visibility
/// follows confirmed collection events and expiry instead of an optimistic
/// deletion that would need to be rolled back.

@ProviderFor(pendingMembershipRemovals)
final pendingMembershipRemovalsProvider = PendingMembershipRemovalsProvider._();

/// Hides declined requests and revoked codes only while their commands send.
///
/// The canonical collections remain intact. When sending ends, visibility
/// follows confirmed collection events and expiry instead of an optimistic
/// deletion that would need to be rolled back.

final class PendingMembershipRemovalsProvider
    extends
        $FunctionalProvider<
          Set<(MembershipRemovalKind, skir.RecordId)>,
          Set<(MembershipRemovalKind, skir.RecordId)>,
          Set<(MembershipRemovalKind, skir.RecordId)>
        >
    with $Provider<Set<(MembershipRemovalKind, skir.RecordId)>> {
  /// Hides declined requests and revoked codes only while their commands send.
  ///
  /// The canonical collections remain intact. When sending ends, visibility
  /// follows confirmed collection events and expiry instead of an optimistic
  /// deletion that would need to be rolled back.
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
    r'fc403fa4da6f2a770b8fbc8292b97e3f96d7a960';

/// Shared display clock refreshed at the next observed membership expiry.
///
/// Visibility providers own and cancel their timers. This local clock filters
/// presentation; server commands still decide whether a request or code is valid.

@ProviderFor(membershipDisplayTime)
final membershipDisplayTimeProvider = MembershipDisplayTimeProvider._();

/// Shared display clock refreshed at the next observed membership expiry.
///
/// Visibility providers own and cancel their timers. This local clock filters
/// presentation; server commands still decide whether a request or code is valid.

final class MembershipDisplayTimeProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Shared display clock refreshed at the next observed membership expiry.
  ///
  /// Visibility providers own and cancel their timers. This local clock filters
  /// presentation; server commands still decide whether a request or code is valid.
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
    r'84e173663f0703f2e9e80089e1dd942831c766f1';

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
    r'f70f8c301cedf4346078b4c8d5b889e3ef64195d';

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
    r'bcd43890f3ab05b76238e5d6c59a0f4803e8d731';
