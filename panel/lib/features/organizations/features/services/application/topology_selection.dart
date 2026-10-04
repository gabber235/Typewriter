part of "services.dart";

/// Identifies a host in the organization topology selection model.
///
/// Use this identifier for grid selection and inspector lookup. The resolved
/// selectable observes both topology and service state because host inspectors
/// include the service that owns the host connection.
class ServiceHostIdentifier extends SelectableIdentifier {
  const ServiceHostIdentifier(this.hostId);

  final skir.RecordId hostId;

  @override
  String get id => "host:${hostId.id}";
  @override
  Object get resourceId => hostId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final topologyState = ref.watch(organizationTopologyStreamProvider);
    final servicesState = ref.watch(canonicalServicesProvider);
    final connections = ref.watch(serviceConnectionsProvider);
    final organization = ref.watch(organizationIdProvider);
    if (topologyState.mapUnready<Selectable>() case final state?) return state;
    if (servicesState.mapUnready<Selectable>() case final state?) return state;

    if (organization == null) {
      return AsyncError(ApiException.noOrganization(), StackTrace.current);
    }
    final topology = topologyState.requireValue;
    final host = topology.hosts.firstWhereOrNull(
      (candidate) => candidate.hostId == hostId,
    );
    if (host == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final projectedServiceState = ref.watch(
      projectedServiceProvider(host.serviceId),
    );
    if (projectedServiceState.mapUnready<Selectable>() case final state?) {
      return state;
    }
    final canonicalService = servicesState.requireValue.firstWhereOrNull(
      (service) => service.serviceId == host.serviceId,
    );
    final service = projectedServiceState.requireValue;
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .services(organization);
    final serviceCommands = canonicalService == null
        ? null
        : ref.watch(
            canonicalOrganizationServicesProvider(organization).notifier,
          );
    final configurationSnapshot = HostEditorSnapshot(host, topology);

    return AsyncData(
      _ServiceHostSelectable(
        id: this,
        host: host,
        service: service,
        topology: topology,
        connected: connections[host.serviceId] ?? false,
        configurationTarget: ResourceEditorTarget(
          targetId: this,
          label: "${service?.displayName ?? host.hostId.id}: configuration",
          resource: HostEditorResource(repository, hostId),
          snapshot: configurationSnapshot,
          commitPolicy: EditorCommitPolicy.applyResource,
          portablePresentation: (source) => topologyHostPortableHost(
            host: host,
            service: service,
            connected: connections[host.serviceId] ?? false,
            configurationOwner: source,
            identityOwner: null,
            realmTargets: configurationSnapshot._realmTargets,
            engineTargets: configurationSnapshot._engineTargets,
            realms: topology.realmInstances
                .where((realm) => realm.ownerHost.id != host.hostId)
                .toList(),
          ),
        ),
        onUnbind: canonicalService == null
            ? null
            : () => serviceCommands!.deleteService(canonicalService.serviceId),
        serviceIdentityTarget: service == null || canonicalService == null
            ? null
            : serviceIdentityTarget(
                id: ServiceIdentifier(service.serviceId),
                service: canonicalService,
                connected: connections[host.serviceId] ?? false,
                repository: repository,
              ),
      ),
    );
  }

  @override
  int get hashCode => hostId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceHostIdentifier && other.hostId == hostId;
}

/// Identifies a loader managed Realm runtime in the organization topology.
///
/// The resolved selectable tracks its owner host and associated service. This
/// allows navigation to be offered only while the owner host is connected.
class RealmInstanceIdentifier extends SelectableIdentifier {
  const RealmInstanceIdentifier(this.realmId);

  final skir.RecordId realmId;

  @override
  String get id => "realm:${realmId.id}";

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final topologyState = ref.watch(organizationTopologyStreamProvider);
    final servicesState = ref.watch(canonicalServicesProvider);
    final connections = ref.watch(serviceConnectionsProvider);
    if (topologyState.mapUnready<Selectable>() case final state?) return state;
    if (servicesState.mapUnready<Selectable>() case final state?) return state;

    final topology = topologyState.requireValue;
    final realm = topology.realmInstances.firstWhereOrNull(
      (candidate) => candidate.realmId == realmId,
    );
    if (realm == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final host = topology.hosts.firstWhereOrNull(
      (candidate) => candidate.hostId == realm.ownerHost.id,
    );
    final service = servicesState.requireValue.firstWhereOrNull(
      (service) => service.serviceId == host?.serviceId,
    );
    final connected = connections[host?.serviceId] ?? false;
    final organization = service?.organization;
    final router = ref.watch(appRouterProvider);

    return AsyncData(
      _RealmInstanceSelectable(
        onOpen: host != null && connected && organization != null
            ? () {
                router.navigate(realmNavigationRoute(organization, realmId));
              }
            : null,
        id: this,
        realm: realm,
        connected: connected,
        host: host,
        service: service,
      ),
    );
  }

  @override
  int get hashCode => realmId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealmInstanceIdentifier && other.realmId == realmId;
}

/// Stable selection identity for an observational engine runtime entry.
///
/// Resolution joins the engine with its owner host and service for display, but
/// exposes no mutation because host configuration is the authoritative command
/// boundary.
class EngineInstanceIdentifier extends SelectableIdentifier {
  const EngineInstanceIdentifier(this.engineId);

  final skir.RecordId engineId;

  @override
  String get id => "engine:${engineId.id}";

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final topologyState = ref.watch(organizationTopologyStreamProvider);
    final servicesState = ref.watch(canonicalServicesProvider);
    if (topologyState.mapUnready<Selectable>() case final state?) return state;
    if (servicesState.mapUnready<Selectable>() case final state?) return state;

    final topology = topologyState.requireValue;
    final engine = topology.engineInstances.firstWhereOrNull(
      (candidate) => candidate.engineId == engineId,
    );
    if (engine == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final host = topology.hosts.firstWhereOrNull(
      (candidate) => candidate.hostId == engine.ownerHost.id,
    );
    return AsyncData(
      _EngineInstanceSelectable(
        id: this,
        engine: engine,
        host: host,
        service: servicesState.requireValue.firstWhereOrNull(
          (service) => service.serviceId == host?.serviceId,
        ),
      ),
    );
  }

  @override
  int get hashCode => engineId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngineInstanceIdentifier && other.engineId == engineId;
}

/// Builds the selectable target catalog advertised by a set of hosts.
Map<String, List<String>> _engineTargetCatalog(
  Iterable<TopologySupportedEngine> engines,
) {
  final versions = <String, Set<String>>{};
  for (final engine in engines) {
    versions.putIfAbsent(engine.engineId, () => <String>{"*"});
  }
  return {
    for (final entry in versions.entries)
      entry.key: entry.value.toList()..sort(),
  };
}

/// Converts host runtime state to the stable label used by inspectors.
String hostRuntimeStatusLabel(TopologyHostStatus status) => switch (status) {
  TopologyHostStatus.offline => "Offline",
  TopologyHostStatus.reconciling => "Reconciling",
  TopologyHostStatus.active => "Active",
  TopologyHostStatus.failed => "Failed",
  TopologyHostStatus.drifted => "Drifted",
  TopologyHostStatus.unknown => "Unknown",
};

/// Gives topology cards and inspectors one stable child lifecycle label.
///
/// Unknown wire values remain visible so forward compatibility does not hide
/// runtime state from operators.
String childRuntimeStatusLabel(TopologyRuntimeStatus status) =>
    switch (status) {
      TopologyRuntimeStatus.absent => "Absent",
      TopologyRuntimeStatus.staging => "Staging",
      TopologyRuntimeStatus.active => "Active",
      TopologyRuntimeStatus.quiescing => "Quiescing",
      TopologyRuntimeStatus.failed => "Failed",
      TopologyRuntimeStatus.rolledBack => "Rolled back",
      TopologyRuntimeStatus.drifted => "Drifted",
      TopologyRuntimeStatus.unknown => "Unknown",
    };

/// Formats a target for display while preserving its engine constraint.
String _targetLabel(TopologyEngineTarget target) =>
    target.versionConstraint == "*"
    ? target.engineId
    : "${target.engineId} ${target.versionConstraint}";

String _encodeTarget(String engineId, String versionConstraint) =>
    "$engineId@$versionConstraint";
