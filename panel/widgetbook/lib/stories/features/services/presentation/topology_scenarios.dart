import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef CompleteTopologyScenario = ({
  skir.OrganizationTopologySnapshot topology,
  List<skir.Service> services,
});

CompleteTopologyScenario completeTopologyScenario() {
  final paperAlpha = _host(
    id: "paper-alpha",
    entrypoint: "PAPER",
    status: skir.HostRuntimeStatus.active,
  );
  final paperBeta = _host(
    id: "paper-beta",
    entrypoint: "PAPER",
    status: skir.HostRuntimeStatus.reconciling,
    appliedRevision: 3,
    canHostRealm: false,
  );
  final realmControl = _host(
    id: "realm-control",
    entrypoint: "STANDALONE",
    status: skir.HostRuntimeStatus.drifted,
    appliedRevision: 2,
  );
  final paperOffline = _host(
    id: "paper-offline",
    entrypoint: "PAPER",
    status: skir.HostRuntimeStatus.offline,
    canHostRealm: false,
  );
  final standaloneFailed = _host(
    id: "standalone-failed",
    entrypoint: "STANDALONE",
    status: skir.HostRuntimeStatus.failed,
    message: "Realm process exited unexpectedly",
  );
  final standaloneQuiescing = _host(
    id: "standalone-quiescing",
    entrypoint: "STANDALONE",
    status: skir.HostRuntimeStatus.active,
  );

  final paperRollback = _host(
    id: "paper-rollback",
    entrypoint: "PAPER",
    status: skir.HostRuntimeStatus.active,
    canHostRealm: false,
  );
  final standaloneAbsent = _host(
    id: "standalone-absent",
    entrypoint: "STANDALONE",
    status: skir.HostRuntimeStatus.active,
  );

  final alphaRealm = _realm(
    id: "adventure",
    host: paperAlpha,
    status: skir.ChildRuntimeStatus.active,
  );
  final stagingRealm = _realm(
    id: "creative",
    host: realmControl,
    status: skir.ChildRuntimeStatus.staging,
  );
  final failedRealm = _realm(
    id: "survival",
    host: standaloneFailed,
    status: skir.ChildRuntimeStatus.failed,
    message: "Manifest activation failed",
  );
  final quiescingRealm = _realm(
    id: "events",
    host: standaloneQuiescing,
    status: skir.ChildRuntimeStatus.quiescing,
  );
  final absentRealm = _realm(
    id: "minigames",
    host: standaloneAbsent,
    status: skir.ChildRuntimeStatus.absent,
  );

  final topology = skir.OrganizationTopologySnapshot(
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
    realms: [
      alphaRealm,
      stagingRealm,
      failedRealm,
      quiescingRealm,
      absentRealm,
    ],
    engines: [
      _engine(
        id: "paper-alpha",
        host: paperAlpha,
        realm: alphaRealm,
        status: skir.ChildRuntimeStatus.active,
      ),
      _engine(
        id: "paper-beta",
        host: paperBeta,
        realm: alphaRealm,
        status: skir.ChildRuntimeStatus.drifted,
      ),
      _engine(
        id: "paper-rollback",
        host: paperRollback,
        realm: quiescingRealm,
        status: skir.ChildRuntimeStatus.rolledBack,
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

skir.ServiceHost _host({
  required String id,
  required String entrypoint,
  required skir.HostRuntimeStatus status,
  int desiredRevision = 4,
  int? appliedRevision,
  bool canHostRealm = true,
  String? message,
}) => skir.ServiceHost(
  hostId: skir.recordId("service_host:$id"),
  serviceId: skir.recordId("service:$id"),
  revision: desiredRevision,
  entrypoint: entrypoint,
  canHostRealm: canHostRealm,
  supportedEngines: [
    skir.SupportedEngine(
      engineId: entrypoint == "PAPER" ? "paper" : "conformance",
    ),
  ],
  topologyRevision: skir.ReconciledRevision(
    desired: desiredRevision,
    applied: appliedRevision ?? desiredRevision,
  ),
  state: skir.HostRuntimeState(
    status: status,
    message: message,
    updatedAt: DateTime.utc(2026, 8, 22, 10, 30),
  ),
);

skir.RealmInstance _realm({
  required String id,
  required skir.ServiceHost host,
  required skir.ChildRuntimeStatus status,
  String? message,
}) => skir.RealmInstance(
  realmId: skir.recordId("realm_instance:$id"),
  ownerHost: _ownerHost(host),
  revision: 3,
  targetEngine: skir.EngineTarget(engineId: "paper", versionConstraint: "^1"),
  state: _runtimeState(status, message: message),
);

skir.EngineInstance _engine({
  required String id,
  required skir.ServiceHost host,
  required skir.RealmInstance realm,
  required skir.ChildRuntimeStatus status,
}) => skir.EngineInstance(
  engineId: skir.recordId("engine_instance:$id"),
  ownerHost: _ownerHost(host),
  realm: skir.RealmInfo(realmId: realm.realmId, ownerHost: realm.ownerHost),
  revision: 5,
  target: skir.EngineTarget(engineId: "paper", versionConstraint: "^1"),
  state: _runtimeState(status),
);

skir.OwnerHost _ownerHost(skir.ServiceHost host) => skir.OwnerHost(
  id: host.hostId,
  name: host.serviceId.id.replaceAll("-", "_"),
);

skir.ChildRuntimeState _runtimeState(
  skir.ChildRuntimeStatus status, {
  String? message,
}) => skir.ChildRuntimeState(
  status: status,
  activeArtifactVersion: status == skir.ChildRuntimeStatus.absent
      ? null
      : "1.4.2",
  message: message,
  updatedAt: DateTime.utc(2026, 8, 22, 10, 30),
);

skir.Service _hostService(skir.ServiceHost host, {required bool online}) =>
    skir.Service(
      serviceId: host.serviceId,
      revision: host.revision,
      name: host.hostId.id.replaceAll("-", "_"),
      role: skir.ServiceRole.createHost(version: "1.0.0"),
      createdAt: DateTime.utc(2026, 8, 19),
      organization: skir.recordId("organization:story"),
      state: skir.ServiceState(
        status: online ? skir.ServiceStatus.online : skir.ServiceStatus.offline,
        lastSeen: online ? DateTime.now() : DateTime.utc(2026, 8, 21),
      ),
      registration: null,
    );

skir.Service _customService({
  required String id,
  required String name,
  required String role,
  required String version,
  required bool online,
}) => skir.Service(
  serviceId: skir.recordId("service:$id"),
  revision: 1,
  name: name,
  role: skir.ServiceRole.createCustom(name: role, version: version),
  createdAt: DateTime.utc(2026, 8, 19),
  organization: skir.recordId("organization:story"),
  state: skir.ServiceState(
    status: online ? skir.ServiceStatus.online : skir.ServiceStatus.offline,
    lastSeen: online ? DateTime.now() : DateTime.utc(2026, 8, 20),
  ),
  registration: null,
);
