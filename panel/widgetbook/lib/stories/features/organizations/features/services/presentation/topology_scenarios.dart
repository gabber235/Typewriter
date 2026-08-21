import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

OrganizationTopology topologyScenario({bool distributed = true}) {
  final paperHost = _host(
    id: "paper-eu-1",
    serviceId: "minecraft-eu-1",
    entrypoint: skir.HostEntrypoint.paper,
    desiredRevision: distributed ? 4 : 3,
    appliedRevision: 3,
  );
  final realmHost = distributed
      ? _host(
          id: "realm-control-1",
          serviceId: "realm-control-1",
          entrypoint: skir.HostEntrypoint.standalone,
          desiredRevision: 8,
          appliedRevision: 8,
        )
      : paperHost;
  final realm = skir.RealmInstance(
    realmId: recordId("realm_instance:adventure"),
    ownerHostId: realmHost.hostId,
    revision: 3,
    targetEngine: skir.EngineTarget(engineId: "paper", majorVersion: 1),
    manifestRevision: skir.ReconciledRevision(desired: 12, applied: 12),
    state: _childState(skir.ChildRuntimeStatus.active),
  );
  final engine = skir.EngineInstance(
    engineId: recordId("engine_instance:paper-eu-1"),
    ownerHostId: paperHost.hostId,
    realmId: realm.realmId,
    revision: 5,
    target: skir.EngineTarget(engineId: "paper", majorVersion: 1),
    manifestRevision: skir.ReconciledRevision(
      desired: 12,
      applied: distributed ? 11 : 12,
    ),
    state: _childState(
      distributed
          ? skir.ChildRuntimeStatus.drifted
          : skir.ChildRuntimeStatus.active,
    ),
  );
  return OrganizationTopology(
    hosts: distributed ? [realmHost, paperHost] : [paperHost],
    realmInstances: [realm],
    engineInstances: [engine],
  );
}

/// Creates service records that own every host in [topology].
///
/// The records stay online so Widgetbook can exercise Realm navigation and
/// host inspectors without depending on a live registration connection.
List<Service> topologyScenarioServices(OrganizationTopology topology) => [
  for (final host in topology.hosts)
    Service(
      serviceId: host.serviceId,
      revision: host.revision,
      name: host.hostId.id.replaceAll("`", "").replaceAll("-", "_"),
      roles: [
        if (topology.realmOwnedBy(host.hostId) != null)
          RealmServiceRole(version: "1.0.0"),
        if (topology.engineOwnedBy(host.hostId) != null)
          EngineServiceRole(version: "1.0.0"),
      ],
      createdAt: DateTime.utc(2026, 8, 19),
      organization: recordId("organization:story"),
      state: ServiceState(
        status: ServiceStateStatus.online,
        lastSeen: DateTime.now(),
      ),
    ),
  Service(
    serviceId: recordId("service:discord"),
    revision: 1,
    name: "discord_bridge",
    roles: [CustomServiceRole(name: "Discord", version: "1.0.0")],
    createdAt: DateTime.utc(2026, 8, 19),
    organization: recordId("organization:story"),
    state: ServiceState(
      status: ServiceStateStatus.online,
      lastSeen: DateTime.now(),
    ),
  ),
];

skir.ServiceHost _host({
  required String id,
  required String serviceId,
  required skir.HostEntrypoint entrypoint,
  required int desiredRevision,
  required int appliedRevision,
}) => skir.ServiceHost(
  hostId: recordId("service_host:$id"),
  serviceId: recordId("service:$serviceId"),
  revision: desiredRevision,
  entrypoint: entrypoint,
  canHostRealm: true,
  supportedEngines: [
    skir.SupportedEngine(
      engineId: entrypoint == skir.HostEntrypoint.paper
          ? "paper"
          : "conformance",
      supportedMajorVersions: [1],
    ),
  ],
  topologyRevision: skir.ReconciledRevision(
    desired: desiredRevision,
    applied: appliedRevision,
  ),
  state: skir.HostRuntimeState(
    status: desiredRevision == appliedRevision
        ? skir.HostRuntimeStatus.active
        : skir.HostRuntimeStatus.reconciling,
    message: null,
    updatedAt: DateTime.utc(2026, 8, 19),
  ),
);

skir.ChildRuntimeState _childState(skir.ChildRuntimeStatus status) =>
    skir.ChildRuntimeState(
      status: status,
      activeArtifactVersion: "1.4.2",
      message: null,
      updatedAt: DateTime.utc(2026, 8, 19),
    );
