import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";
import "package:typewriter_testkit/src/traits/services/services_data.dart";

/// The open organization runs [services] and the runtime [topology], as the
/// backend reports them over NATS.
///
/// Like [backendOverNats], the panel's real organization list, topology and
/// services projections run against [World.nats]; this trait answers their
/// first requests with the signed in user's organizations, [topology] and
/// [services]. Commands such as a rename or a host configuration reach the
/// handlers the test registers, and changes arrive through
/// [ServicesBackendEvents].
Trait servicesBackend({
  List<skir.Service> services = const [],
  skir.OrganizationTopologySnapshot? topology,
}) => _ServicesBackend(
  services,
  topology ?? skir.OrganizationTopologySnapshot.defaultInstance,
);

final class _ServicesBackend extends Trait {
  const _ServicesBackend(this.services, this.topology);

  final List<skir.Service> services;
  final skir.OrganizationTopologySnapshot topology;

  @override
  Slot get slot => const Slot("backend");

  @override
  String get description =>
      "servicesBackend(${services.length} services, "
      "${topology.hosts.length} hosts)";

  @override
  void applyTo(WorldBuilder world) {
    world
      ..organizationDoubles = false
      ..onStart((started) {
        final user = world.user;
        final organization = world.organizations.firstOrNull;
        if (user == null || organization == null) return;
        final scope = "cloud.to.user.${user.id.transportIdentity}.organization";
        final id = organization.organizationId.id.transportIdentity;
        started.nats
          ..registerHandler(
            "$scope.watch",
            (_) => skir.WatchUserOrganizationsResponse.serializer.toBytes(
              skir.WatchUserOrganizationsResponse.wrapSnapshot(
                skir.UserOrganizationsSnapshot(
                  sequence: 1,
                  values: world.organizations,
                ),
              ),
            ),
          )
          ..registerHandler(
            "$scope.$id.topology.watch",
            (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
              skir.WatchOrganizationTopologyResponse.wrapList(topology),
            ),
          )
          ..registerHandler(
            "$scope.$id.services.watch",
            (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
              skir.WatchOrganizationServicesResponse.wrapList(services),
            ),
          );
      });
  }
}

/// Changes the backend announces to every organization member watching.
extension ServicesBackendEvents on FakeNats {
  /// Announces [change] to the topology of [organization].
  void announceTopology(
    skir.RecordId organization,
    skir.OrganizationTopologyChanged change,
  ) => connection.emitMessageOnSubject(
    "cloud.from.organization.${organization.id.transportIdentity}"
    ".topology.watch",
    skir.OrganizationTopologyChanged.serializer.toBytes(change),
  );

  /// Confirms every host configuration requested on [subject] with [change]
  /// and returns the requests, in the order they arrive.
  List<skir.ConfigureServiceHostRequest> confirmHostConfigurations(
    String subject,
    skir.HostConfigurationChange change,
  ) {
    final sent = <skir.ConfigureServiceHostRequest>[];
    registerHandler(subject, (data) {
      sent.add(skir.ConfigureServiceHostRequest.serializer.fromBytes(data));
      return configuredReply(change);
    });
    return sent;
  }

  /// The names every service rename requested on [subject] sent, in order.
  List<String> sentServiceNames(String subject) => [
    for (final request in requestsTo(subject))
      skir.UpdateOrganizationServiceRequest.serializer
          .fromBytes(request.payload)
          .name,
  ];

  /// Announces [change] to the services of [organization].
  void announceServices(
    skir.RecordId organization,
    skir.OrganizationServicesChanged change,
  ) => connection.emitMessageOnSubject(
    "cloud.from.organization.${organization.id.transportIdentity}"
    ".services.watch",
    skir.OrganizationServicesChanged.serializer.toBytes(change),
  );
}
