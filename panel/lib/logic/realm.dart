import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";

part "realm.g.dart";

@riverpod
String? realmId(Ref ref) {
  return ref.watch(routeParamProvider("realmId"));
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
