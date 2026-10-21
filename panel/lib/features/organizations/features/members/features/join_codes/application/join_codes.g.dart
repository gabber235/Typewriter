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
/// [MembershipResourceRepository] owns commands and supplies confirmed facts.
/// Derived visibility hides expired and pending rows without changing this
/// authoritative snapshot.

@ProviderFor(OrganizationJoinCodes)
final organizationJoinCodesProvider = OrganizationJoinCodesProvider._();

/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// [MembershipResourceRepository] owns commands and supplies confirmed facts.
/// Derived visibility hides expired and pending rows without changing this
/// authoritative snapshot.
final class OrganizationJoinCodesProvider
    extends
        $StreamNotifierProvider<OrganizationJoinCodes, List<skir.JoinCode>> {
  /// Owns the panel's live read model of invitation codes for the selected organization.
  ///
  /// The provider waits for authentication and organization selection, then
  /// watches the service for one snapshot followed by sequenced add and remove
  /// changes. Duplicate changes are ignored. A sequence gap invalidates the
  /// provider so the next subscription can recover from a fresh snapshot.
  /// [MembershipResourceRepository] owns commands and supplies confirmed facts.
  /// Derived visibility hides expired and pending rows without changing this
  /// authoritative snapshot.
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
    r'41cf9a4c7e2bd6fadd3c27ce52052dac95fad11c';

/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// [MembershipResourceRepository] owns commands and supplies confirmed facts.
/// Derived visibility hides expired and pending rows without changing this
/// authoritative snapshot.

abstract class _$OrganizationJoinCodes
    extends $StreamNotifier<List<skir.JoinCode>> {
  Stream<List<skir.JoinCode>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<skir.JoinCode>>, List<skir.JoinCode>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<skir.JoinCode>>, List<skir.JoinCode>>,
              AsyncValue<List<skir.JoinCode>>,
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
/// allowed. Display time filters the authoritative projection without writing
/// to its sequence state.

@ProviderFor(joinCodeCount)
final joinCodeCountProvider = JoinCodeCountProvider._();

/// Derives the number of currently usable codes from the live projection.
///
/// Loading and error states intentionally report zero because this value is a
/// navigation badge, not an authority for whether generation or revocation is
/// allowed. Display time filters the authoritative projection without writing
/// to its sequence state.

final class JoinCodeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Derives the number of currently usable codes from the live projection.
  ///
  /// Loading and error states intentionally report zero because this value is a
  /// navigation badge, not an authority for whether generation or revocation is
  /// allowed. Display time filters the authoritative projection without writing
  /// to its sequence state.
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

String _$joinCodeCountHash() => r'3a7646c360801cb33cdf610bf7b7b6e66e50daf0';
