import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/services_service.dart";

/// The open organization runs [services] and the runtime [topology], and its
/// backend keeps every service command the panel sends: binding, renaming,
/// unbinding and configuring a host show their outcome.
///
/// Like [servicesBackend], the panel's real organization list, topology and
/// services projections run over NATS, here against a
/// [FakeServicesService]. Null [services] or a false [topologyArrives] never
/// arrive, so the page keeps loading, or fails with [failure] when one is
/// given. Commands answer after the world's latency, or fail with
/// [commandFailure] when one is given.
Trait servicesService({
  List<skir.Service>? services = const [],
  skir.OrganizationTopologySnapshot? topology,
  bool topologyArrives = true,
  Object? failure,
  Object? commandFailure,
}) => _ServicesService(
  () => FakeServicesService(
    services: services,
    topology: topology,
    topologyArrives: topologyArrives,
    failure: failure,
    commandFailure: commandFailure,
  ),
  services?.length ?? 0,
);

/// Builds a fresh backend for each world, so a trait list shared between
/// tests never carries one test's commands into the next.
final class _ServicesService extends Trait {
  const _ServicesService(this.create, this.serviceCount);

  final FakeServicesService Function() create;
  final int serviceCount;

  @override
  Slot get slot => const Slot("backend");

  @override
  String get description => "servicesService($serviceCount services)";

  @override
  void applyTo(WorldBuilder world) {
    world
      ..organizationDoubles = false
      ..onStart((started) {
        final user = world.user;
        if (user == null || world.organizations.isEmpty) return;
        create()
          ..latency = world.latency
          ..serve(
            started.nats,
            user: user.id,
            organizations: world.organizations,
          );
      });
  }
}
