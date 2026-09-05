import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

Service generateRandomService({
  skir.RecordId? organization,
  ServiceRole? role,
}) {
  final generatedRole = faker.randomGenerator.boolean()
      ? HostServiceRole(version: generateRandomVersion().canonicalizedVersion)
      : CustomServiceRole(
          name: "integration",
          version: generateRandomVersion().canonicalizedVersion,
        );
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
    revision: 1,
    name: faker.lorem
        .words(faker.randomGenerator.integer(3, min: 1))
        .join("_")
        .toLowerCase(),
    role: role ?? generatedRole,
    createdAt: createdAt,
    state: ServiceState(
      status: online ? ServiceStateStatus.online : ServiceStateStatus.offline,
      lastSeen: lastSeen,
    ),
    organization: organization ?? recordId("organization:${faker.guid.guid()}"),
  );
}

class ServicesMock extends Services {
  ServicesMock({required this.displayState});
  final DisplayState displayState;
  @override
  Stream<List<Service>> build() async* {
    yield await displayState.generateBatch((count) {
      final organization = recordId("organization:${faker.guid.guid()}");
      return List.generate(count, (index) {
        final role = switch (index) {
          0 => HostServiceRole(
            version: generateRandomVersion().canonicalizedVersion,
          ),
          1 => CustomServiceRole(
            name: "realm",
            version: generateRandomVersion().canonicalizedVersion,
          ),
          _ => null,
        };
        return generateRandomService(organization: organization, role: role);
      });
    });
  }

  @override
  Future<void> bindService(String token) async =>
      Future<void>.delayed(const Duration(milliseconds: 1000));
  @override
  Future<TypedMutationResult> updateService(Service service) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final canonical = service.copyWith(revision: service.revision + 1);
    state = AsyncData(
      (await future)
          .map(
            (value) => value.serviceId == service.serviceId ? canonical : value,
          )
          .toList(),
    );
    return TypedMutationResult.success(
      revision: canonical.revision,
      value: canonical.inspectorValue,
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
    (ref) => ref.watch(realmsProvider).value?.firstOrNull?.realmId,
  ),
  selectedRealmProvider.overrideWith(
    (ref) async => (await ref.watch(realmsProvider.future)).firstOrNull,
  ),
];
