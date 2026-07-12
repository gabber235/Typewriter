import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_panel/utils/skir.dart";

part "realm.g.dart";

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
  return services
      .where((s) => s.serviceTypes.contains(ServiceType.SERVICE_TYPE_REALM))
      .toList();
}
