// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_codes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// Mutations use this same owner to reconcile successful events and to roll
/// back an optimistic revoke when the request fails.

@ProviderFor(OrganizationJoinCodes)
final organizationJoinCodesProvider = OrganizationJoinCodesProvider._();

/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// Mutations use this same owner to reconcile successful events and to roll
/// back an optimistic revoke when the request fails.
final class OrganizationJoinCodesProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinCodes,
          List<OrganizationJoinCode>
        > {
  /// Owns the panel's live read model of invitation codes for the selected organization.
  ///
  /// The provider waits for authentication and organization selection, then
  /// watches the service for one snapshot followed by sequenced add and remove
  /// changes. Duplicate changes are ignored. A sequence gap invalidates the
  /// provider so the next subscription can recover from a fresh snapshot.
  /// Mutations use this same owner to reconcile successful events and to roll
  /// back an optimistic revoke when the request fails.
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
    r'0139bb87120daaf6a0b821c1e20dbaf9db8d7dc8';

/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// Mutations use this same owner to reconcile successful events and to roll
/// back an optimistic revoke when the request fails.

abstract class _$OrganizationJoinCodes
    extends $StreamNotifier<List<OrganizationJoinCode>> {
  Stream<List<OrganizationJoinCode>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// Derives the number of currently usable codes from the live projection.
///
/// Loading and error states intentionally report zero because this value is a
/// navigation badge, not an authority for whether generation or revocation is
/// allowed. Expired codes remain in the projection until the visible countdown
/// removes them locally or a service change replaces the snapshot.

@ProviderFor(joinCodeCount)
final joinCodeCountProvider = JoinCodeCountProvider._();

/// Derives the number of currently usable codes from the live projection.
///
/// Loading and error states intentionally report zero because this value is a
/// navigation badge, not an authority for whether generation or revocation is
/// allowed. Expired codes remain in the projection until the visible countdown
/// removes them locally or a service change replaces the snapshot.

final class JoinCodeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Derives the number of currently usable codes from the live projection.
  ///
  /// Loading and error states intentionally report zero because this value is a
  /// navigation badge, not an authority for whether generation or revocation is
  /// allowed. Expired codes remain in the projection until the visible countdown
  /// removes them locally or a service change replaces the snapshot.
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
