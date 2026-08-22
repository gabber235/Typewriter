import "package:typewriter_panel/typewriter_panel.dart";

typedef CompleteTopologyScenario = ({
  OrganizationTopology topology,
  List<Service> services,
});

CompleteTopologyScenario completeTopologyScenario() {
  final paperAlpha = _host(
    id: "paper-alpha",
    entrypoint: "PAPER",
    status: TopologyHostStatus.active,
  );
  final paperBeta = _host(
    id: "paper-beta",
    entrypoint: "PAPER",
    status: TopologyHostStatus.reconciling,
    appliedRevision: 3,
    canHostRealm: false,
  );
  final realmControl = _host(
    id: "realm-control",
    entrypoint: "STANDALONE",
    status: TopologyHostStatus.drifted,
    appliedRevision: 2,
  );
  final paperOffline = _host(
    id: "paper-offline",
    entrypoint: "PAPER",
    status: TopologyHostStatus.offline,
    canHostRealm: false,
  );
  final standaloneFailed = _host(
    id: "standalone-failed",
    entrypoint: "STANDALONE",
    status: TopologyHostStatus.failed,
    message: "Realm process exited unexpectedly",
  );
  final standaloneQuiescing = _host(
    id: "standalone-quiescing",
    entrypoint: "STANDALONE",
    status: TopologyHostStatus.active,
  );
  final paperRollback = _host(
    id: "paper-rollback",
    entrypoint: "PAPER",
    status: TopologyHostStatus.active,
    canHostRealm: false,
  );
  final standaloneAbsent = _host(
    id: "standalone-absent",
    entrypoint: "STANDALONE",
    status: TopologyHostStatus.active,
  );

  final alphaRealm = _realm(
    id: "adventure",
    host: paperAlpha,
    status: TopologyRuntimeStatus.active,
  );
  final stagingRealm = _realm(
    id: "creative",
    host: realmControl,
    status: TopologyRuntimeStatus.staging,
  );
  final failedRealm = _realm(
    id: "survival",
    host: standaloneFailed,
    status: TopologyRuntimeStatus.failed,
    message: "Manifest activation failed",
  );
  final quiescingRealm = _realm(
    id: "events",
    host: standaloneQuiescing,
    status: TopologyRuntimeStatus.quiescing,
  );
  final absentRealm = _realm(
    id: "minigames",
    host: standaloneAbsent,
    status: TopologyRuntimeStatus.absent,
  );

  final topology = OrganizationTopology(
    hosts: [
      paperAlpha,
      paperBeta,
      realmControl,
      paperOffline,
      standaloneFailed,
      standaloneQuiescing,
      paperRollback,
      standaloneAbsent,
    ],
    realmInstances: [
      alphaRealm,
      stagingRealm,
      failedRealm,
      quiescingRealm,
      absentRealm,
    ],
    engineInstances: [
      _engine(
        id: "paper-alpha",
        host: paperAlpha,
        realm: alphaRealm,
        status: TopologyRuntimeStatus.active,
      ),
      _engine(
        id: "paper-beta",
        host: paperBeta,
        realm: alphaRealm,
        status: TopologyRuntimeStatus.drifted,
      ),
      _engine(
        id: "paper-rollback",
        host: paperRollback,
        realm: quiescingRealm,
        status: TopologyRuntimeStatus.rolledBack,
      ),
    ],
  );

  return (
    topology: topology,
    services: [
      for (final host in topology.hosts)
        _hostService(host, online: host != paperOffline),
      _customService(
        id: "discord",
        name: "discord_bridge",
        role: "discord",
        version: "2.4.0",
        online: true,
      ),
      _customService(
        id: "analytics",
        name: "quest_analytics",
        role: "analytics",
        version: "1.8.2",
        online: true,
      ),
      _customService(
        id: "backups",
        name: "realm_backups",
        role: "backups",
        version: "3.1.0",
        online: false,
      ),
      _customService(
        id: "webhooks",
        name: "webhook_gateway",
        role: "webhooks",
        version: "1.2.1",
        online: false,
      ),
    ],
  );
}

TopologyHost _host({
  required String id,
  required String entrypoint,
  required TopologyHostStatus status,
  int desiredRevision = 4,
  int? appliedRevision,
  bool canHostRealm = true,
  String? message,
}) => TopologyHost(
  hostId: recordId("service_host:$id"),
  serviceId: recordId("service:$id"),
  revision: desiredRevision,
  entrypoint: entrypoint,
  canHostRealm: canHostRealm,
  supportedEngines: [
    TopologySupportedEngine(
      engineId: entrypoint == "PAPER" ? "paper" : "conformance",
      supportedMajorVersions: const [1],
    ),
  ],
  topologyRevision: TopologyRevision(
    desired: desiredRevision,
    applied: appliedRevision ?? desiredRevision,
  ),
  state: TopologyHostState(
    status: status,
    message: message,
    updatedAt: DateTime.utc(2026, 8, 22, 10, 30),
  ),
);

TopologyRealm _realm({
  required String id,
  required TopologyHost host,
  required TopologyRuntimeStatus status,
  String? message,
}) => TopologyRealm(
  realmId: recordId("realm_instance:$id"),
  ownerHost: _ownerHost(host),
  revision: 3,
  targetEngine: const TopologyEngineTarget(engineId: "paper", majorVersion: 1),
  manifestRevision: const TopologyRevision(desired: 12, applied: 12),
  state: _runtimeState(status, message: message),
);

TopologyEngine _engine({
  required String id,
  required TopologyHost host,
  required TopologyRealm realm,
  required TopologyRuntimeStatus status,
}) => TopologyEngine(
  engineId: recordId("engine_instance:$id"),
  ownerHost: _ownerHost(host),
  realm: TopologyRealmInfo(realmId: realm.realmId, ownerHost: realm.ownerHost),
  revision: 5,
  target: const TopologyEngineTarget(engineId: "paper", majorVersion: 1),
  manifestRevision: TopologyRevision(
    desired: 12,
    applied: status == TopologyRuntimeStatus.drifted ? 11 : 12,
  ),
  state: _runtimeState(status),
);

TopologyOwnerHost _ownerHost(TopologyHost host) => TopologyOwnerHost(
  id: host.hostId,
  name: host.serviceId.id.replaceAll("-", "_"),
);

TopologyRuntimeState _runtimeState(
  TopologyRuntimeStatus status, {
  String? message,
}) => TopologyRuntimeState(
  status: status,
  activeArtifactVersion: status == TopologyRuntimeStatus.absent
      ? null
      : "1.4.2",
  message: message,
  updatedAt: DateTime.utc(2026, 8, 22, 10, 30),
);

Service _hostService(TopologyHost host, {required bool online}) => Service(
  serviceId: host.serviceId,
  revision: host.revision,
  name: host.hostId.id.replaceAll("-", "_"),
  role: HostServiceRole(version: "1.0.0"),
  createdAt: DateTime.utc(2026, 8, 19),
  organization: recordId("organization:story"),
  state: ServiceState(
    status: online ? ServiceStateStatus.online : ServiceStateStatus.offline,
    lastSeen: online ? DateTime.now() : DateTime.utc(2026, 8, 21),
  ),
);

Service _customService({
  required String id,
  required String name,
  required String role,
  required String version,
  required bool online,
}) => Service(
  serviceId: recordId("service:$id"),
  revision: 1,
  name: name,
  role: CustomServiceRole(name: role, version: version),
  createdAt: DateTime.utc(2026, 8, 19),
  organization: recordId("organization:story"),
  state: ServiceState(
    status: online ? ServiceStateStatus.online : ServiceStateStatus.offline,
    lastSeen: online ? DateTime.now() : DateTime.utc(2026, 8, 20),
  ),
);
