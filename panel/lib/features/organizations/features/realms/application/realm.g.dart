// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup.

@ProviderFor(realmId)
final realmIdProvider = RealmIdProvider._();

/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup.

final class RealmIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
  /// Resolves the route's realm parameter to the typed topology identifier.
  ///
  /// A missing parameter deliberately remains `null`; it represents the
  /// organization level route, not a failed lookup.
  RealmIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmIdHash();

  @$internal
  @override
  $ProviderElement<skir.RecordId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.RecordId? create(Ref ref) {
    return realmId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.RecordId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.RecordId?>(value),
    );
  }
}

String _$realmIdHash() => r'ffb152dbb33d651fc8a22b7ec72cdcb852832b60';

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.

@ProviderFor(selectedRealm)
final selectedRealmProvider = SelectedRealmProvider._();

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.

final class SelectedRealmProvider
    extends
        $FunctionalProvider<
          AsyncValue<TopologyRealm?>,
          TopologyRealm?,
          FutureOr<TopologyRealm?>
        >
    with $FutureModifier<TopologyRealm?>, $FutureProvider<TopologyRealm?> {
  /// Finds the selected realm in the organization topology projection.
  ///
  /// Topology is the authority for realm identity, owner host, lifecycle status,
  /// and last update time. A valid route identifier with no matching entry yields
  /// `null`, allowing connection policy to distinguish absence from inactivity.
  SelectedRealmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRealmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRealmHash();

  @$internal
  @override
  $FutureProviderElement<TopologyRealm?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TopologyRealm?> create(Ref ref) {
    return selectedRealm(ref);
  }
}

String _$selectedRealmHash() => r'c519620c0a77a2ee3ece7e8496937fb6a3d5ca59';

/// Exposes all realms in the current organization topology for selection UI.

@ProviderFor(realms)
final realmsProvider = RealmsProvider._();

/// Exposes all realms in the current organization topology for selection UI.

final class RealmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopologyRealm>>,
          List<TopologyRealm>,
          FutureOr<List<TopologyRealm>>
        >
    with
        $FutureModifier<List<TopologyRealm>>,
        $FutureProvider<List<TopologyRealm>> {
  /// Exposes all realms in the current organization topology for selection UI.
  RealmsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmsHash();

  @$internal
  @override
  $FutureProviderElement<List<TopologyRealm>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopologyRealm>> create(Ref ref) {
    return realms(ref);
  }
}

String _$realmsHash() => r'a6a67271ad2071acc9794999988313a29132975d';

@ProviderFor(realmsAvailability)
final realmsAvailabilityProvider = RealmsAvailabilityProvider._();

final class RealmsAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<skir.RecordId, bool>>,
          Map<skir.RecordId, bool>,
          FutureOr<Map<skir.RecordId, bool>>
        >
    with
        $FutureModifier<Map<skir.RecordId, bool>>,
        $FutureProvider<Map<skir.RecordId, bool>> {
  RealmsAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmsAvailabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmsAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<Map<skir.RecordId, bool>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<skir.RecordId, bool>> create(Ref ref) {
    return realmsAvailability(ref);
  }
}

String _$realmsAvailabilityHash() =>
    r'532257b4f8b2634c6ab50ad9af1dd3f9cea11b04';

/// Derives the connection gate consumed by the workspace and editor providers.
///
/// The selected realm must resolve, report an active runtime status, and have
/// its owner host connected. Resolution failures become [unavailable]; known
/// inactive or disconnected realms become [offline]. Topology invalidation is
/// the recovery path, and causes Riverpod to reevaluate this stream.

@ProviderFor(realmConnection)
final realmConnectionProvider = RealmConnectionProvider._();

/// Derives the connection gate consumed by the workspace and editor providers.
///
/// The selected realm must resolve, report an active runtime status, and have
/// its owner host connected. Resolution failures become [unavailable]; known
/// inactive or disconnected realms become [offline]. Topology invalidation is
/// the recovery path, and causes Riverpod to reevaluate this stream.

final class RealmConnectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmConnectionState>,
          RealmConnectionState,
          Stream<RealmConnectionState>
        >
    with
        $FutureModifier<RealmConnectionState>,
        $StreamProvider<RealmConnectionState> {
  /// Derives the connection gate consumed by the workspace and editor providers.
  ///
  /// The selected realm must resolve, report an active runtime status, and have
  /// its owner host connected. Resolution failures become [unavailable]; known
  /// inactive or disconnected realms become [offline]. Topology invalidation is
  /// the recovery path, and causes Riverpod to reevaluate this stream.
  RealmConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmConnectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmConnectionHash();

  @$internal
  @override
  $StreamProviderElement<RealmConnectionState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RealmConnectionState> create(Ref ref) {
    return realmConnection(ref);
  }
}

String _$realmConnectionHash() => r'4a138358818b34afa64c45a4107bb05a1f356342';

/// Provides a synchronous interaction policy for widgets during async checks.
///
/// Before the first connection value, a selected realm is conservatively
/// [RealmConnectionState.checking]. This prevents edits during the uncertainty
/// window instead of exposing a stale enabled surface.

@ProviderFor(realmInteraction)
final realmInteractionProvider = RealmInteractionProvider._();

/// Provides a synchronous interaction policy for widgets during async checks.
///
/// Before the first connection value, a selected realm is conservatively
/// [RealmConnectionState.checking]. This prevents edits during the uncertainty
/// window instead of exposing a stale enabled surface.

final class RealmInteractionProvider
    extends
        $FunctionalProvider<
          RealmInteractionState,
          RealmInteractionState,
          RealmInteractionState
        >
    with $Provider<RealmInteractionState> {
  /// Provides a synchronous interaction policy for widgets during async checks.
  ///
  /// Before the first connection value, a selected realm is conservatively
  /// [RealmConnectionState.checking]. This prevents edits during the uncertainty
  /// window instead of exposing a stale enabled surface.
  RealmInteractionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmInteractionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmInteractionHash();

  @$internal
  @override
  $ProviderElement<RealmInteractionState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmInteractionState create(Ref ref) {
    return realmInteraction(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmInteractionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmInteractionState>(value),
    );
  }
}

String _$realmInteractionHash() => r'c5ab3f670a6f9d86721d1555509b4ca8239b6b85';
