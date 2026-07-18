import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/features/organizations/features/services/application/services.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

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
  return services.where((service) => service.isRealm).toList();
}
