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
  AsyncValue<Selectable> create(Ref ref) =>
      _topologySelectable(ref, (topology, services) {
        final host = topology.hosts.firstWhereOrNull(
          (candidate) => candidate.hostId == hostId,
        );
        if (host == null) throw SelectableNotFoundException(this);
        return _ServiceHostSelectable(
          ref: ref,
          id: this,
          host: host,
          service: services.firstWhereOrNull(
            (service) => service.serviceId == host.serviceId,
          ),
          topology: topology,
        );
      });

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
  AsyncValue<Selectable> create(Ref ref) =>
      _topologySelectable(ref, (topology, services) {
        final realm = topology.realmInstances.firstWhereOrNull(
          (candidate) => candidate.realmId == realmId,
        );
        if (realm == null) throw SelectableNotFoundException(this);
        final host = topology.hosts.firstWhereOrNull(
          (candidate) => candidate.hostId == realm.ownerHost.id,
        );
        return _RealmInstanceSelectable(
          ref: ref,
          id: this,
          realm: realm,
          host: host,
          service: services.firstWhereOrNull(
            (service) => service.serviceId == host?.serviceId,
          ),
        );
      });

  @override
  int get hashCode => realmId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealmInstanceIdentifier && other.realmId == realmId;
}

/// Identifies a loader managed execution engine in the topology selection.
class EngineInstanceIdentifier extends SelectableIdentifier {
  const EngineInstanceIdentifier(this.engineId);

  final skir.RecordId engineId;

  @override
  String get id => "engine:${engineId.id}";

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      _topologySelectable(ref, (topology, services) {
        final engine = topology.engineInstances.firstWhereOrNull(
          (candidate) => candidate.engineId == engineId,
        );
        if (engine == null) throw SelectableNotFoundException(this);
        final host = topology.hosts.firstWhereOrNull(
          (candidate) => candidate.hostId == engine.ownerHost.id,
        );
        return _EngineInstanceSelectable(
          id: this,
          engine: engine,
          host: host,
          service: services.firstWhereOrNull(
            (service) => service.serviceId == host?.serviceId,
          ),
        );
      });

  @override
  int get hashCode => engineId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngineInstanceIdentifier && other.engineId == engineId;
}

AsyncValue<Selectable> _topologySelectable(
  Ref ref,
  Selectable Function(OrganizationTopology, List<Service>) create,
) {
  final topology = ref.watch(organizationTopologyStreamProvider);
  final services = ref.watch(servicesProvider);
  if (topology case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  if (services case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  if (!topology.hasValue || !services.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(create(topology.requireValue, services.requireValue));
}

Map<String, List<int>> _engineTargetCatalog(
  Iterable<skir.SupportedEngine> engines,
) {
  final versions = <String, Set<int>>{};
  for (final engine in engines) {
    versions
        .putIfAbsent(engine.engineId, () => <int>{})
        .addAll(engine.supportedMajorVersions);
  }
  return {
    for (final entry in versions.entries)
      entry.key: entry.value.toList()..sort(),
  };
}

String hostRuntimeStatusLabel(skir.HostRuntimeStatus status) =>
    switch (status) {
      skir.HostRuntimeStatus.offline => "Offline",
      skir.HostRuntimeStatus.reconciling => "Reconciling",
      skir.HostRuntimeStatus.active => "Active",
      skir.HostRuntimeStatus.failed => "Failed",
      skir.HostRuntimeStatus.drifted => "Drifted",
      skir.HostRuntimeStatus_unknown() => "Unknown",
    };

/// Gives topology cards and inspectors one stable child lifecycle label.
///
/// Unknown wire values remain visible so forward compatibility does not hide
/// runtime state from operators.
String childRuntimeStatusLabel(skir.ChildRuntimeStatus status) =>
    switch (status) {
      skir.ChildRuntimeStatus.absent => "Absent",
      skir.ChildRuntimeStatus.staging => "Staging",
      skir.ChildRuntimeStatus.active => "Active",
      skir.ChildRuntimeStatus.quiescing => "Quiescing",
      skir.ChildRuntimeStatus.failed => "Failed",
      skir.ChildRuntimeStatus.rolledBack => "Rolled back",
      skir.ChildRuntimeStatus.drifted => "Drifted",
      skir.ChildRuntimeStatus_unknown() => "Unknown",
    };

String _revisionLabel(skir.ReconciledRevision revision) =>
    "${revision.applied} of ${revision.desired}";

String _targetLabel(skir.EngineTarget target) =>
    "${target.engineId.formatted} ${target.majorVersion}.x";

String _encodeTarget(String engineId, int majorVersion) =>
    "$engineId@$majorVersion";
