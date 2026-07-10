import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/realm.dart";
import "package:typewriter_panel/logic/services.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

Service generateRandomService() {
  final types = <ServiceType>[];
  if (faker.randomGenerator.boolean()) {
    types.add(ServiceType.SERVICE_TYPE_ENGINE);
  }
  if (faker.randomGenerator.boolean() || types.isEmpty) {
    types.add(ServiceType.SERVICE_TYPE_REALM);
  }

  final createdAt = faker.date.dateTimeBetween(
    DateTime.now().subtract(365.days),
    DateTime.now().subtract(14.days),
  );

  final online = faker.randomGenerator.integer(10) != 0;
  final lastSeen = online
      ? faker.date.dateTimeBetween(
          DateTime.now().subtract(2.minutes),
          DateTime.now(),
        )
      : faker.date.dateTimeBetween(createdAt, DateTime.now().subtract(14.days));

  final state = ServiceState()
    ..status = online
        ? ServiceStatus.SERVICE_STATUS_ONLINE
        : ServiceStatus.SERVICE_STATUS_OFFLINE
    ..lastSeen = lastSeen.toTimestamp();

  return Service()
    ..serviceId = faker.guid.guid()
    ..name = faker.lorem
        .words(faker.randomGenerator.integer(3, min: 1))
        .join("_")
        .toLowerCase()
    ..serviceTypes.addAll(types)
    ..createdAt = createdAt.toTimestamp()
    ..state = state
    ..organizationId = faker.guid.guid();
}

class ServicesMock extends Services {
  ServicesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<Service>> build() async* {
    yield await displayState.generate(generateRandomService);
  }

  @override
  Future<void> bindService(String token) async {
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Future<void> updateService(Service service) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final services = await future;

    state = AsyncData(
      services
          .map((s) => s.serviceId == service.serviceId ? service : s)
          .toList(),
    );
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final services = await future;

    state = AsyncData(services.where((s) => s.serviceId != serviceId).toList());
  }
}

List<Override> servicesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [servicesProvider.overrideWith(() => ServicesMock(displayState: state))];

List<Override> realmProviderOverrides() => [
  realmIdProvider.overrideWith(
    (ref) => ref
        .watch(realmsProvider)
        .whenData((realms) {
          final serviceId = realms.firstOrNull?.serviceId;
          if (serviceId == null) return null;
          return skir.RecordId(
            table: "service",
            key: skir.RecordIdKey.wrapString(serviceId),
          );
        })
        .value,
  ),
  selectedRealmProvider.overrideWith((ref) async {
    final realms = await ref.watch(realmsProvider.future);
    return realms.firstOrNull;
  }),
];
