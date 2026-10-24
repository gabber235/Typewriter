// Realm selection is route state, while availability is derived from the
// organization topology and the selected realm's owner host. The resulting
// interaction state is the shared gate used by the organization workspace:
// presentation may remain mounted while mutations and navigation are paused.

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm.freezed.dart";
part "realm.g.dart";

/// Describes whether the selected realm can currently receive workspace work.
///
/// [checking] is transient while topology is resolved. [offline] means the
/// realm is known but inactive or its owner host is disconnected. [unavailable]
/// means the selected realm could not be resolved, so callers should retry or
/// choose another realm rather than treat it as an offline runtime.
enum RealmConnectionState {
  notSelected,
  checking,
  online,
  offline,
  unavailable,
}

/// Reloads topology when a previously disconnected service becomes available.
///
/// Service heartbeats are independent from topology observations. A recovered
/// service therefore provides a reliable opportunity to replace any topology
/// event that core NATS could not deliver while the panel was disconnected.
/// The first observation belongs to startup, not recovery. Refreshing it would
/// invalidate the topology snapshot that is already being initialized.
/// A snapshot already in progress owns reconciliation and is not replaced.
@riverpod
void realmTopologyRecovery(Ref ref) {
  final organizationId = ref.watch(organizationIdProvider);
  if (organizationId == null) return;

  ref.listen(serviceConnectionsProvider, (previous, next) {
    final recovered = next.entries.any(
      (entry) => entry.value && previous?[entry.key] == false,
    );
    if (!recovered) return;
    // Recovery is an effect on the topology owner. Dispatch it after the current
    // provider derivation pass so dependants cannot rebuild twice in that pass.
    unawaited(
      Future<void>.microtask(() {
        if (!ref.mounted) return;
        final topology = organizationTopologyControllerProvider(organizationId);
        if (ref.read(topology).isLoading) return;
        ref.read(topology.notifier).refresh();
      }),
    );
  });
}

/// UI policy derived from [RealmConnectionState].
///
/// The state has no independent lifecycle or mutable authority. Widgets use
/// [suspended] to block edits while preserving the current view, then rebuild
/// when the connection provider emits a new state.
@freezed
abstract class RealmInteractionState with _$RealmInteractionState {
  const factory RealmInteractionState({
    required RealmConnectionState connectionState,
  }) = _RealmInteractionState;

  const RealmInteractionState._();

  bool get suspended => switch (connectionState) {
    RealmConnectionState.notSelected || RealmConnectionState.online => false,
    RealmConnectionState.checking ||
    RealmConnectionState.offline ||
    RealmConnectionState.unavailable => true,
  };
}

/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup.
@riverpod
skir.RecordId? realmId(Ref ref) {
  final id = ref.watch(routeParamProvider("realmId"));
  if (id == null) return null;
  return skir.recordId("realm_instance:$id");
}

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.
/// Ready topology observations are projected without an asynchronous boundary,
/// while initial resolution and explicit topology refreshes remain pending.
@riverpod
FutureOr<skir.RealmInstance?> selectedRealm(Ref ref) {
  final id = ref.watch(realmIdProvider);
  if (id == null) return null;
  final topology = ref
      .watch(organizationTopologyProvider)
      .unwrapPrevious()
      .requireValue;
  return topology.realms.firstWhereOrNull((realm) => realm.realmId == id);
}

/// Exposes all realms in the current organization topology for selection UI.
@riverpod
Future<List<skir.RealmInstance>> realms(Ref ref) async {
  final topology = await ref.watch(organizationTopologyProvider.future);
  return topology.realms.toList();
}

@riverpod
Future<Map<skir.RecordId, bool>> realmsAvailability(Ref ref) async {
  final realms = await ref.watch(realmsProvider.future);

  return realms
      .map(
        (realm) => MapEntry(
          realm.realmId,
          ref.watch(hostConnectedProvider(realm.ownerHost.id)),
        ),
      )
      .toMap();
}

/// Derives the connection gate consumed by the workspace and editor providers.
///
/// The selected realm must resolve, report an active runtime status, and have
/// its owner host connected. Resolution failures become [unavailable]; known
/// inactive or disconnected realms become [offline]. Topology invalidation is
/// the recovery path, and causes Riverpod to reevaluate this result.
@riverpod
FutureOr<RealmConnectionState> realmConnection(Ref ref) {
  final id = ref.watch(realmIdProvider);
  if (id == null) {
    return RealmConnectionState.notSelected;
  }

  final selected = ref.watch(selectedRealmProvider).unwrapPrevious();
  if (selected.hasError) {
    return RealmConnectionState.unavailable;
  }
  final realm = selected.requireValue;

  if (realm == null) {
    return RealmConnectionState.unavailable;
  }

  if (realm.state.status != skir.ChildRuntimeStatus.active ||
      !ref.watch(hostConnectedProvider(realm.ownerHost.id))) {
    return RealmConnectionState.offline;
  }

  return RealmConnectionState.online;
}

/// Provides a synchronous interaction policy for widgets during async checks.
///
/// Before the first connection value, a selected realm is conservatively
/// [RealmConnectionState.checking]. This prevents edits during the uncertainty
/// window instead of exposing a stale enabled surface.
@riverpod
RealmInteractionState realmInteraction(Ref ref) {
  final realmId = ref.watch(realmIdProvider);
  final connection = ref.watch(realmConnectionProvider);
  final connectionState = connection.isLoading
      ? (realmId == null
            ? RealmConnectionState.notSelected
            : RealmConnectionState.checking)
      : connection.value ?? RealmConnectionState.unavailable;
  return RealmInteractionState(connectionState: connectionState);
}
