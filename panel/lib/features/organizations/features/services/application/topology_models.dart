part of "services.dart";

@freezed
abstract class TopologyRevision with _$TopologyRevision {
  const factory TopologyRevision({required int desired, required int applied}) =
      _TopologyRevision;

  factory TopologyRevision.fromSkir(skir.ReconciledRevision revision) =>
      TopologyRevision(desired: revision.desired, applied: revision.applied);
}

@freezed
abstract class TopologyEngineTarget with _$TopologyEngineTarget {
  const factory TopologyEngineTarget({
    required String engineId,
    required int majorVersion,
  }) = _TopologyEngineTarget;

  factory TopologyEngineTarget.fromSkir(skir.EngineTarget target) =>
      TopologyEngineTarget(
        engineId: target.engineId,
        majorVersion: target.majorVersion,
      );

  const TopologyEngineTarget._();

  skir.EngineTarget toSkir() =>
      skir.EngineTarget(engineId: engineId, majorVersion: majorVersion);
}

@freezed
abstract class TopologySupportedEngine with _$TopologySupportedEngine {
  const factory TopologySupportedEngine({
    required String engineId,
    required List<int> supportedMajorVersions,
  }) = _TopologySupportedEngine;

  factory TopologySupportedEngine.fromSkir(skir.SupportedEngine engine) =>
      TopologySupportedEngine(
        engineId: engine.engineId,
        supportedMajorVersions: engine.supportedMajorVersions.toList(),
      );
}

enum TopologyHostStatus {
  offline,
  reconciling,
  active,
  failed,
  drifted,
  unknown;

  factory TopologyHostStatus.fromSkir(skir.HostRuntimeStatus status) =>
      switch (status) {
        skir.HostRuntimeStatus.offline => TopologyHostStatus.offline,
        skir.HostRuntimeStatus.reconciling => TopologyHostStatus.reconciling,
        skir.HostRuntimeStatus.active => TopologyHostStatus.active,
        skir.HostRuntimeStatus.failed => TopologyHostStatus.failed,
        skir.HostRuntimeStatus.drifted => TopologyHostStatus.drifted,
        skir.HostRuntimeStatus_unknown() => TopologyHostStatus.unknown,
      };
}

@freezed
abstract class TopologyHostState with _$TopologyHostState {
  const factory TopologyHostState({
    required TopologyHostStatus status,
    required String? message,
    required DateTime updatedAt,
  }) = _TopologyHostState;

  factory TopologyHostState.fromSkir(skir.HostRuntimeState state) =>
      TopologyHostState(
        status: TopologyHostStatus.fromSkir(state.status),
        message: state.message,
        updatedAt: state.updatedAt,
      );
}

enum TopologyRuntimeStatus {
  absent,
  staging,
  active,
  quiescing,
  failed,
  rolledBack,
  drifted,
  unknown;

  factory TopologyRuntimeStatus.fromSkir(skir.ChildRuntimeStatus status) =>
      switch (status) {
        skir.ChildRuntimeStatus.absent => TopologyRuntimeStatus.absent,
        skir.ChildRuntimeStatus.staging => TopologyRuntimeStatus.staging,
        skir.ChildRuntimeStatus.active => TopologyRuntimeStatus.active,
        skir.ChildRuntimeStatus.quiescing => TopologyRuntimeStatus.quiescing,
        skir.ChildRuntimeStatus.failed => TopologyRuntimeStatus.failed,
        skir.ChildRuntimeStatus.rolledBack => TopologyRuntimeStatus.rolledBack,
        skir.ChildRuntimeStatus.drifted => TopologyRuntimeStatus.drifted,
        skir.ChildRuntimeStatus_unknown() => TopologyRuntimeStatus.unknown,
      };
}

@freezed
abstract class TopologyRuntimeState with _$TopologyRuntimeState {
  const factory TopologyRuntimeState({
    required TopologyRuntimeStatus status,
    required String? activeArtifactVersion,
    required String? message,
    required DateTime updatedAt,
  }) = _TopologyRuntimeState;

  factory TopologyRuntimeState.fromSkir(skir.ChildRuntimeState state) =>
      TopologyRuntimeState(
        status: TopologyRuntimeStatus.fromSkir(state.status),
        activeArtifactVersion: state.activeArtifactVersion,
        message: state.message,
        updatedAt: state.updatedAt,
      );
}

@freezed
abstract class TopologyOwnerHost with _$TopologyOwnerHost {
  const factory TopologyOwnerHost({
    required skir.RecordId id,
    required String name,
  }) = _TopologyOwnerHost;

  factory TopologyOwnerHost.fromSkir(skir.OwnerHost owner) =>
      TopologyOwnerHost(id: owner.id, name: owner.name);
}

@freezed
abstract class TopologyRealmInfo with _$TopologyRealmInfo {
  const factory TopologyRealmInfo({
    required skir.RecordId realmId,
    required TopologyOwnerHost ownerHost,
  }) = _TopologyRealmInfo;

  factory TopologyRealmInfo.fromSkir(skir.RealmInfo realm) => TopologyRealmInfo(
    realmId: realm.realmId,
    ownerHost: TopologyOwnerHost.fromSkir(realm.ownerHost),
  );
}

@freezed
abstract class TopologyHost with _$TopologyHost {
  const factory TopologyHost({
    required skir.RecordId hostId,
    required skir.RecordId serviceId,
    required int revision,
    required String entrypoint,
    required bool canHostRealm,
    required List<TopologySupportedEngine> supportedEngines,
    required TopologyRevision topologyRevision,
    required TopologyHostState state,
  }) = _TopologyHost;

  factory TopologyHost.fromSkir(skir.ServiceHost host) => TopologyHost(
    hostId: host.hostId,
    serviceId: host.serviceId,
    revision: host.revision,
    entrypoint: host.entrypoint,
    canHostRealm: host.canHostRealm,
    supportedEngines: host.supportedEngines
        .map(TopologySupportedEngine.fromSkir)
        .toList(),
    topologyRevision: TopologyRevision.fromSkir(host.topologyRevision),
    state: TopologyHostState.fromSkir(host.state),
  );
}

@freezed
abstract class TopologyRealm with _$TopologyRealm {
  const factory TopologyRealm({
    required skir.RecordId realmId,
    required TopologyOwnerHost ownerHost,
    required int revision,
    required TopologyEngineTarget targetEngine,
    required TopologyRevision manifestRevision,
    required TopologyRuntimeState state,
  }) = _TopologyRealm;

  factory TopologyRealm.fromSkir(skir.RealmInstance realm) => TopologyRealm(
    realmId: realm.realmId,
    ownerHost: TopologyOwnerHost.fromSkir(realm.ownerHost),
    revision: realm.revision,
    targetEngine: TopologyEngineTarget.fromSkir(realm.targetEngine),
    manifestRevision: TopologyRevision.fromSkir(realm.manifestRevision),
    state: TopologyRuntimeState.fromSkir(realm.state),
  );
}

@freezed
abstract class TopologyEngine with _$TopologyEngine {
  const factory TopologyEngine({
    required skir.RecordId engineId,
    required TopologyOwnerHost ownerHost,
    required TopologyRealmInfo realm,
    required int revision,
    required TopologyEngineTarget target,
    required TopologyRevision manifestRevision,
    required TopologyRuntimeState state,
  }) = _TopologyEngine;

  factory TopologyEngine.fromSkir(skir.EngineInstance engine) => TopologyEngine(
    engineId: engine.engineId,
    ownerHost: TopologyOwnerHost.fromSkir(engine.ownerHost),
    realm: TopologyRealmInfo.fromSkir(engine.realm),
    revision: engine.revision,
    target: TopologyEngineTarget.fromSkir(engine.target),
    manifestRevision: TopologyRevision.fromSkir(engine.manifestRevision),
    state: TopologyRuntimeState.fromSkir(engine.state),
  );
}

@freezed
abstract class TopologyConfigurationResult with _$TopologyConfigurationResult {
  const factory TopologyConfigurationResult({
    required TopologyHost host,
    required TopologyRealm? realm,
    required TopologyEngine? engine,
  }) = _TopologyConfigurationResult;

  factory TopologyConfigurationResult.fromSkir(
    skir.ConfigureServiceHostResponse_Success result,
  ) => TopologyConfigurationResult(
    host: TopologyHost.fromSkir(result.host),
    realm: result.realm == null ? null : TopologyRealm.fromSkir(result.realm!),
    engine: result.engine == null
        ? null
        : TopologyEngine.fromSkir(result.engine!),
  );
}

@freezed
abstract class OrganizationTopology with _$OrganizationTopology {
  const factory OrganizationTopology({
    required List<TopologyHost> hosts,
    required List<TopologyRealm> realmInstances,
    required List<TopologyEngine> engineInstances,
  }) = _OrganizationTopology;

  const OrganizationTopology._();

  static const empty = OrganizationTopology(
    hosts: [],
    realmInstances: [],
    engineInstances: [],
  );

  TopologyRealm? realmOwnedBy(skir.RecordId hostId) {
    for (final realm in realmInstances) {
      if (realm.ownerHost.id == hostId) return realm;
    }
    return null;
  }

  TopologyEngine? engineOwnedBy(skir.RecordId hostId) {
    for (final engine in engineInstances) {
      if (engine.ownerHost.id == hostId) return engine;
    }
    return null;
  }
}
