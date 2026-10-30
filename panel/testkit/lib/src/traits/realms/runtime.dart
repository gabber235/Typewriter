import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/doubles/organizations.dart";
import "package:typewriter_testkit/src/traits/services/services_backend.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The topology the backend reports for [organization], Acme by default,
/// when the Realm named [name], Main by default as `realm(...)` seeds it,
/// runs on its own active host with its runtime in [status].
skir.OrganizationTopologySnapshot realmRuntimeTopology(
  skir.ChildRuntimeStatus status, {
  skir.RecordId? organization,
  String name = "Main",
}) {
  final scope = organization ?? acme.organizationId;
  final topology =
      (FakeOrganizations()..addRealm(
            scope,
            id: skir.recordId("realm_instance:${name.toLowerCase()}"),
            name: name,
          ))
          .topology(scope);
  return (topology.toMutable()
        ..realms = [
          for (final realm in topology.realms)
            (realm.toMutable()
                  ..state = (realm.state.toMutable()..status = status)
                      .toFrozen())
                .toFrozen(),
        ])
      .toFrozen();
}

/// The backend reports, over NATS, the Realm named [name] of [organization]
/// with its runtime in [status] while its host keeps running; see
/// [realmRuntimeTopology].
///
/// Like [servicesBackend], whose slot it takes, the panel's real topology
/// and services projections run against the world's NATS server.
Trait realmRuntime(
  skir.ChildRuntimeStatus status, {
  skir.RecordId? organization,
  String name = "Main",
}) {
  final scope = organization ?? acme.organizationId;
  final services =
      (FakeOrganizations()..addRealm(
            scope,
            id: skir.recordId("realm_instance:${name.toLowerCase()}"),
            name: name,
          ))
          .services(scope);
  return servicesBackend(
    topology: realmRuntimeTopology(status, organization: scope, name: name),
    services: services,
  );
}
