import "dart:async";

import "package:faker/faker.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

Service generateRandomService() {
  final types = <ServiceType>[];
  if (faker.randomGenerator.boolean()) {
    types.add(ServiceType.SERVICE_TYPE_ENGINE);
  }
  if (faker.randomGenerator.boolean() || types.isEmpty) {
    types.add(ServiceType.SERVICE_TYPE_REALM);
  }

  return Service()
    ..id = faker.guid.guid()
    ..name = faker.lorem
        .words(faker.randomGenerator.integer(3, min: 1))
        .join(" ")
    ..serviceTypes.addAll(types)
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
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> updateService(Service service) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final services = await future;

    state = AsyncData(
      services.map((s) => s.id == service.id ? service : s).toList(),
    );
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final services = await future;

    state = AsyncData(services.where((s) => s.id != serviceId).toList());
  }
}

List<Override> servicesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [servicesProvider.overrideWith(() => ServicesMock(displayState: state))];
