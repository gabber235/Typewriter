// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reloads topology when a previously disconnected service becomes available.
///
/// Service heartbeats are independent from topology observations. A recovered
/// service therefore provides a reliable opportunity to replace any topology
/// event that core NATS could not deliver while the panel was disconnected.
/// The first observation belongs to startup, not recovery. Refreshing it would
/// invalidate the topology snapshot that is already being initialized.
/// A snapshot already in progress owns reconciliation and is not replaced.

@ProviderFor(realmTopologyRecovery)
final realmTopologyRecoveryProvider = RealmTopologyRecoveryProvider._();

/// Reloads topology when a previously disconnected service becomes available.
///
/// Service heartbeats are independent from topology observations. A recovered
/// service therefore provides a reliable opportunity to replace any topology
/// event that core NATS could not deliver while the panel was disconnected.
/// The first observation belongs to startup, not recovery. Refreshing it would
/// invalidate the topology snapshot that is already being initialized.
/// A snapshot already in progress owns reconciliation and is not replaced.

final class RealmTopologyRecoveryProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Reloads topology when a previously disconnected service becomes available.
  ///
  /// Service heartbeats are independent from topology observations. A recovered
  /// service therefore provides a reliable opportunity to replace any topology
  /// event that core NATS could not deliver while the panel was disconnected.
  /// The first observation belongs to startup, not recovery. Refreshing it would
  /// invalidate the topology snapshot that is already being initialized.
  /// A snapshot already in progress owns reconciliation and is not replaced.
  RealmTopologyRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmTopologyRecoveryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmTopologyRecoveryHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return realmTopologyRecovery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$realmTopologyRecoveryHash() =>
    r'f348cf5a32d4c8b7b89d47326e35f623b48d7a8c';

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.
/// Ready topology observations are projected without an asynchronous boundary,
/// while initial resolution and explicit topology refreshes remain pending.

@ProviderFor(selectedRealm)
final selectedRealmProvider = SelectedRealmProvider._();

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.
/// Ready topology observations are projected without an asynchronous boundary,
/// while initial resolution and explicit topology refreshes remain pending.

final class SelectedRealmProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.RealmInstance?>,
          skir.RealmInstance?,
          FutureOr<skir.RealmInstance?>
        >
    with
        $FutureModifier<skir.RealmInstance?>,
        $FutureProvider<skir.RealmInstance?> {
  /// Finds the selected realm in the organization topology projection.
  ///
  /// Topology is the authority for realm identity, owner host, lifecycle status,
  /// and last update time. A valid route identifier with no matching entry yields
  /// `null`, allowing connection policy to distinguish absence from inactivity.
  /// Ready topology observations are projected without an asynchronous boundary,
  /// while initial resolution and explicit topology refreshes remain pending.
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
  $FutureProviderElement<skir.RealmInstance?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.RealmInstance?> create(Ref ref) {
    return selectedRealm(ref);
  }
}

String _$selectedRealmHash() => r'47d5331beb42b2132e28cd7501be85cd7db60d0f';

/// Exposes all realms in the current organization topology for selection UI.

@ProviderFor(realms)
final realmsProvider = RealmsProvider._();

/// Exposes all realms in the current organization topology for selection UI.

final class RealmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<skir.RealmInstance>>,
          List<skir.RealmInstance>,
          FutureOr<List<skir.RealmInstance>>
        >
    with
        $FutureModifier<List<skir.RealmInstance>>,
        $FutureProvider<List<skir.RealmInstance>> {
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
  $FutureProviderElement<List<skir.RealmInstance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<skir.RealmInstance>> create(Ref ref) {
    return realms(ref);
  }
}

String _$realmsHash() => r'76efc4d64e5b22b8d70d472918bfe3b71d0c67fc';

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
/// the recovery path, and causes Riverpod to reevaluate this result.

@ProviderFor(realmConnection)
final realmConnectionProvider = RealmConnectionProvider._();

/// Derives the connection gate consumed by the workspace and editor providers.
///
/// The selected realm must resolve, report an active runtime status, and have
/// its owner host connected. Resolution failures become [unavailable]; known
/// inactive or disconnected realms become [offline]. Topology invalidation is
/// the recovery path, and causes Riverpod to reevaluate this result.

final class RealmConnectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmConnectionState>,
          RealmConnectionState,
          FutureOr<RealmConnectionState>
        >
    with
        $FutureModifier<RealmConnectionState>,
        $FutureProvider<RealmConnectionState> {
  /// Derives the connection gate consumed by the workspace and editor providers.
  ///
  /// The selected realm must resolve, report an active runtime status, and have
  /// its owner host connected. Resolution failures become [unavailable]; known
  /// inactive or disconnected realms become [offline]. Topology invalidation is
  /// the recovery path, and causes Riverpod to reevaluate this result.
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
  $FutureProviderElement<RealmConnectionState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RealmConnectionState> create(Ref ref) {
    return realmConnection(ref);
  }
}

String _$realmConnectionHash() => r'644d37a03b10e813ca546812566cccef1dc69fd3';

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

String _$realmInteractionHash() => r'53d08c62de035e50e7d0a4b2bb5afdffb32f2ac3';
