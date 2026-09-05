import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm.freezed.dart";
part "realm.g.dart";

enum RealmConnectionState {
  notSelected,
  checking,
  online,
  offline,
  unavailable,
}

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

@riverpod
skir.RecordId? realmId(Ref ref) {
  final id = ref.watch(routeParamProvider("realmId"));
  if (id == null) return null;
  return recordId("realm_instance:$id");
}

@riverpod
Future<TopologyRealm?> selectedRealm(Ref ref) async {
  final id = ref.watch(realmIdProvider);
  if (id == null) return null;
  final topology = await ref.watch(organizationTopologyStreamProvider.future);
  return topology.realmInstances.firstWhereOrNull(
    (realm) => realm.realmId == id,
  );
}

@riverpod
Future<List<TopologyRealm>> realms(Ref ref) async {
  final topology = await ref.watch(organizationTopologyStreamProvider.future);
  return topology.realmInstances;
}

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

  if (realm.state.status != TopologyRuntimeStatus.active) {
    yield RealmConnectionState.offline;
    return;
  }

  yield RealmConnectionState.online;
}

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
