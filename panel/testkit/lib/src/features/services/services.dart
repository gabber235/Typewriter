import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:faker/faker.dart";

import "package:typewriter_testkit/src/shared/testing/testing.dart";

skir.Service generateRandomService({
  skir.RecordId? organization,
  skir.ServiceRole? role,
}) {
  final generatedRole = faker.randomGenerator.boolean()
      ? skir.ServiceRole.createHost(
          version: generateRandomVersion().canonicalizedVersion,
        )
      : skir.ServiceRole.createCustom(
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
  return skir.Service(
    serviceId: skir.recordId("service:${faker.guid.guid()}"),
    revision: 1,
    name: faker.lorem
        .words(faker.randomGenerator.integer(3, min: 1))
        .join("_")
        .toLowerCase(),
    role: role ?? generatedRole,
    createdAt: createdAt,
    state: skir.ServiceState(
      status: online ? skir.ServiceStatus.online : skir.ServiceStatus.offline,
      lastSeen: lastSeen,
    ),
    organization:
        organization ?? skir.recordId("organization:${faker.guid.guid()}"),
    registration: null,
  );
}

class ServicesMock extends CanonicalOrganizationServices {
  ServicesMock({required this.displayState});
  final DisplayState displayState;

  @override
  Stream<List<skir.Service>> build(skir.RecordId organizationId) async* {
    yield await displayState.generateBatch((count) {
      final organization = skir.recordId("organization:${faker.guid.guid()}");
      return List.generate(count, (index) {
        final role = switch (index) {
          0 => skir.ServiceRole.createHost(
            version: generateRandomVersion().canonicalizedVersion,
          ),
          1 => skir.ServiceRole.createCustom(
            name: "realm",
            version: generateRandomVersion().canonicalizedVersion,
          ),
          _ => null,
        };
        return generateRandomService(organization: organization, role: role);
      });
    });
  }
}

List<Override> canonicalServicesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [
  canonicalOrganizationServicesProvider.overrideWith2(
    (_) => ServicesMock(displayState: state),
  ),
];

List<Override> realmProviderOverrides() => [
  realmIdProvider.overrideWith(
    (ref) => ref.watch(realmsProvider).value?.firstOrNull?.realmId,
  ),
  selectedRealmProvider.overrideWith(
    (ref) async => (await ref.watch(realmsProvider.future)).firstOrNull,
  ),
];
