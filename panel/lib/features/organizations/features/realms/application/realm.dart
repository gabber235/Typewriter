import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm.g.dart";

enum RealmConnectionState {
  notSelected,
  checking,
  online,
  offline,
  unavailable,
}

class RealmInteractionState {
  const RealmInteractionState({required this.connectionState});

  final RealmConnectionState connectionState;

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
  return recordId("service:$id");
}

@riverpod
Future<Service?> selectedRealm(Ref ref) async {
  final id = ref.watch(realmIdProvider);
  if (id == null) return null;
  final services = await ref.watch(servicesProvider.future);
  return services.firstWhereOrNull((s) => s.serviceId == id);
}

@riverpod
Future<List<Service>> realms(Ref ref) async {
  final services = await ref.watch(servicesProvider.future);
  return services.where((service) => service.isRealm).toList();
}

@riverpod
Stream<RealmConnectionState> realmConnection(Ref ref) async* {
  final id = ref.watch(realmIdProvider);
  if (id == null) {
    yield RealmConnectionState.notSelected;
    return;
  }

  yield RealmConnectionState.checking;

  Service? realm;
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

  if (!realm.isOnline) {
    yield RealmConnectionState.offline;
    return;
  }

  yield RealmConnectionState.online;
  final delay = realm.nextTimeout.difference(DateTime.now());
  if (delay > Duration.zero) {
    await Future<void>.delayed(delay);
  }
  yield RealmConnectionState.offline;
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
