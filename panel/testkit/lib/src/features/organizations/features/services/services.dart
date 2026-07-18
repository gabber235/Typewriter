import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm.dart";
import "package:typewriter_panel/features/organizations/features/services/application/services.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

Service generateRandomService() {
  final roles = <skir.ServiceRole>[];
  if (faker.randomGenerator.boolean()) {
    roles.add(skir.ServiceRole.createEngine(version: "1.0.0"));
  }
  if (faker.randomGenerator.boolean() || roles.isEmpty) {
    roles.add(skir.ServiceRole.createRealm(version: "1.0.0"));
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
  return Service(
    serviceId: recordId("service:${faker.guid.guid()}"),
    name: faker.lorem
        .words(faker.randomGenerator.integer(3, min: 1))
        .join("_")
        .toLowerCase(),
    roles: roles,
    createdAt: createdAt,
    state: skir.ServiceState(
      status: online ? skir.ServiceStatus.online : skir.ServiceStatus.offline,
      lastSeen: lastSeen,
    ),
    organization: recordId("organization:${faker.guid.guid()}"),
  );
}

class ServicesMock extends Services {
  ServicesMock({required this.displayState});
  final DisplayState displayState;
  @override
  Stream<List<Service>> build() async* {
    yield await displayState.generate(generateRandomService);
  }

  @override
  Future<void> bindService(String token) async =>
      Future<void>.delayed(const Duration(milliseconds: 1000));
  @override
  Future<void> updateService(Service service) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = AsyncData(
      (await future)
          .map(
            (value) => value.serviceId == service.serviceId ? service : value,
          )
          .toList(),
    );
  }

  @override
  Future<void> deleteService(skir.RecordId serviceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = AsyncData(
      (await future)
          .where((service) => service.serviceId != serviceId)
          .toList(),
    );
  }
}

List<Override> servicesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [servicesProvider.overrideWith(() => ServicesMock(displayState: state))];

List<Override> realmProviderOverrides() => [
  realmIdProvider.overrideWith(
    (ref) => ref.watch(realmsProvider).value?.firstOrNull?.serviceId,
  ),
  selectedRealmProvider.overrideWith(
    (ref) async => (await ref.watch(realmsProvider.future)).firstOrNull,
  ),
];
