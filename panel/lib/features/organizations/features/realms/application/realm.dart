// Realm selection is route state, while availability is derived from the
// organization topology and the selected realm's owner host. The resulting
// interaction state is the shared gate used by the organization workspace:
// presentation may remain mounted while mutations and navigation are paused.
import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
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

@freezed
/// UI policy derived from [RealmConnectionState].
///
/// The state has no independent lifecycle or mutable authority. Widgets use
/// [suspended] to block edits while preserving the current view, then rebuild
/// when the connection provider emits a new state.
/// UI interaction policy derived from [RealmConnectionState].
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
  return recordId("realm_instance:$id");
}

/// Finds the selected realm in the organization topology projection.
///
/// Topology is the authority for realm identity, owner host, lifecycle status,
/// and last update time. A valid route identifier with no matching entry yields
/// `null`, allowing connection policy to distinguish absence from inactivity.
@riverpod
Future<TopologyRealm?> selectedRealm(Ref ref) async {
  final id = ref.watch(realmIdProvider);
  if (id == null) return null;
  final topology = await ref.watch(organizationTopologyStreamProvider.future);
  return topology.realmInstances.firstWhereOrNull(
    (realm) => realm.realmId == id,
  );
}

/// Exposes all realms in the current organization topology for selection UI.
@riverpod
Future<List<TopologyRealm>> realms(Ref ref) async {
  final topology = await ref.watch(organizationTopologyStreamProvider.future);
  return topology.realmInstances;
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
/// the recovery path, and causes Riverpod to reevaluate this stream.
@riverpod
Stream<RealmConnectionState> realmConnection(Ref ref) async* {
  final id = ref.watch(realmIdProvider);
  if (id == null) {
    yield RealmConnectionState.notSelected;
    return;
  }

  yield RealmConnectionState.checking;

  TopologyRealm? realm;
  try {
    realm = await ref.watch(selectedRealmProvider.future);
  } on Object {
    yield RealmConnectionState.unavailable;
    return;
  }

  if (realm == null) {
    yield RealmConnectionState.unavailable;
    return;
  }

  if (realm.state.status != TopologyRuntimeStatus.active ||
      !ref.watch(hostConnectedProvider(realm.ownerHost.id))) {
    yield RealmConnectionState.offline;
    return;
  }

  yield RealmConnectionState.online;
}

/// Provides a synchronous interaction policy for widgets during async checks.
///
/// Before the first connection value, a selected realm is conservatively
/// [RealmConnectionState.checking]. This prevents edits during the uncertainty
/// window instead of exposing a stale enabled surface.
@riverpod
RealmInteractionState realmInteraction(Ref ref) {
  final realmId = ref.watch(realmIdProvider);
  final connectionState =
      ref.watch(realmConnectionProvider).value ??
      (realmId == null
          ? RealmConnectionState.notSelected
          : RealmConnectionState.checking);
  return RealmInteractionState(connectionState: connectionState);
}
