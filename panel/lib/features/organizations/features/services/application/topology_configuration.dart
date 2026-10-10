part of "services.dart";

/// Applies topology watch and mutation changes to the controller's owned
/// immutable projection.
///
/// Configuration changes update the desired and applied revision view and
/// replace the affected child resources. Observation changes update runtime
/// state only. Timestamp and revision checks prevent an older observation from
/// erasing newer knowledge when responses and watch events overlap.
extension OrganizationTopologyConfiguration on OrganizationTopology {
  /// Uses incoming snapshot membership and retains accepted configuration and
  /// runtime progress only for resources that remain present.
  OrganizationTopology reconcileSnapshot(OrganizationTopology previous) =>
      copyWith(
        hosts: [
          for (final incoming in hosts)
            incoming.reconcileSnapshot(
              previous.hosts.firstWhereOrNull(
                (item) => item.hostId == incoming.hostId,
              ),
            ),
        ],
        realmInstances: [
          for (final incoming in realmInstances)
            incoming.reconcileSnapshot(
              previous.realmInstances.firstWhereOrNull(
                (item) => item.realmId == incoming.realmId,
              ),
            ),
        ],
        engineInstances: [
          for (final incoming in engineInstances)
            incoming.reconcileSnapshot(
              previous.engineInstances.firstWhereOrNull(
                (item) => item.engineId == incoming.engineId,
              ),
            ),
        ],
      );

  /// Merges a host runtime observation without changing its desired
  /// configuration.
  OrganizationTopology applyHostObservation(TopologyHost incoming) {
    final previous = hosts.firstWhereOrNull(
      (host) => host.hostId == incoming.hostId,
    );
    if (previous == null) return copyWith(hosts: [...hosts, incoming]);
    if (incoming.state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return copyWith(
      hosts: hosts.upsertByKey(
        (host) => host.hostId,
        previous.copyWith(
          state: incoming.state,
          topologyRevision: previous.topologyRevision.copyWith(
            applied: incoming.topologyRevision.applied,
          ),
        ),
      ),
    );
  }

  /// Merges a realm runtime observation owned by a host.
  OrganizationTopology applyRealmObservation(TopologyRealm incoming) {
    final previous = realmInstances.firstWhereOrNull(
      (realm) => realm.realmId == incoming.realmId,
    );
    if (previous == null ||
        incoming.state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return copyWith(
      realmInstances: realmInstances.upsertByKey(
        (realm) => realm.realmId,
        previous.copyWith(state: incoming.state),
      ),
    );
  }

  /// Merges an engine runtime observation owned by a host.
  OrganizationTopology applyEngineObservation(TopologyEngine incoming) {
    final previous = engineInstances.firstWhereOrNull(
      (engine) => engine.engineId == incoming.engineId,
    );
    if (previous == null ||
        incoming.state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return copyWith(
      engineInstances: engineInstances.upsertByKey(
        (engine) => engine.engineId,
        previous.copyWith(state: incoming.state),
      ),
    );
  }

  /// Applies one complete backend configuration change as one projection.
  ///
  /// The change is authoritative for the affected desired configuration and
  /// child resource membership. Newer runtime observations already held by the
  /// projection are retained. Repeated changes and overlapping response or
  /// watch delivery are safe to merge without treating configuration as proof
  /// of runtime activation.
  OrganizationTopology applyConfiguration(skir.HostConfigurationChange change) {
    var host = TopologyHost.fromSkir(change.host);
    final previousHost = hosts.firstWhereOrNull(
      (item) => item.hostId == host.hostId,
    );
    if (previousHost != null) {
      if (previousHost.revision > host.revision) return this;
      if (previousHost.state.updatedAt.isAfter(host.state.updatedAt)) {
        host = host.copyWith(
          state: previousHost.state,
          topologyRevision: host.topologyRevision.copyWith(
            applied: previousHost.topologyRevision.applied,
          ),
        );
      }
    }
    final removed = change.removedResources.toSet();
    var realms = realmInstances
        .where(
          (item) =>
              !removed.contains(item.realmId) &&
              (item.ownerHost.id != host.hostId ||
                  item.realmId == change.realm?.realmId),
        )
        .toList();
    var engines = engineInstances
        .where(
          (item) =>
              !removed.contains(item.engineId) &&
              (item.ownerHost.id != host.hostId ||
                  item.engineId == change.engine?.engineId),
        )
        .toList();

    if (change.realm case final value?) {
      var realm = TopologyRealm.fromSkir(value);
      final previous = realms.firstWhereOrNull(
        (item) => item.realmId == realm.realmId,
      );
      if (previous != null &&
          previous.state.updatedAt.isAfter(realm.state.updatedAt)) {
        realm = realm.copyWith(state: previous.state);
      }
      realms = realms.upsertByKey((item) => item.realmId, realm);
    }
    if (change.engine case final value?) {
      var engine = TopologyEngine.fromSkir(value);
      final previous = engines.firstWhereOrNull(
        (item) => item.engineId == engine.engineId,
      );
      if (previous != null &&
          previous.state.updatedAt.isAfter(engine.state.updatedAt)) {
        engine = engine.copyWith(state: previous.state);
      }
      engines = engines.upsertByKey((item) => item.engineId, engine);
    }
    return copyWith(
      hosts: hosts.upsertByKey((item) => item.hostId, host),
      realmInstances: realms,
      engineInstances: engines,
    );
  }

  /// Applies one compound runtime report as one immutable projection update.
  OrganizationTopology applyRuntimeObservation(
    skir.HostExecutionObservation observation,
  ) {
    var next = applyHostObservation(TopologyHost.fromSkir(observation.host));
    if (observation.realm case final observed?) {
      final previous = next.realmInstances.firstWhereOrNull(
        (realm) => realm.realmId == observed.realmId,
      );
      if (previous != null) {
        next = next.applyRealmObservation(
          previous.copyWith(
            state: TopologyRuntimeState.fromSkir(observed.state),
          ),
        );
      }
    }
    if (observation.engine case final observed?) {
      final previous = next.engineInstances.firstWhereOrNull(
        (engine) => engine.engineId == observed.engineId,
      );
      if (previous != null) {
        next = next.applyEngineObservation(
          previous.copyWith(
            state: TopologyRuntimeState.fromSkir(observed.state),
          ),
        );
      }
    }
    return next;
  }

  /// Accepts host discovery without treating it as child membership authority.
  OrganizationTopology applyAdvertisement(skir.ServiceHost advertisement) {
    final incoming = TopologyHost.fromSkir(advertisement);
    final previous = hosts.firstWhereOrNull(
      (host) => host.hostId == incoming.hostId,
    );
    final accepted = incoming.reconcileSnapshot(previous);
    return copyWith(hosts: hosts.upsertByKey((host) => host.hostId, accepted));
  }
}

extension TopologyHostSnapshotProgress on TopologyHost {
  TopologyHost reconcileSnapshot(TopologyHost? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    final observation =
        previous.state.updatedAt.isAfter(incoming.state.updatedAt)
        ? previous
        : incoming;
    return configuration.copyWith(
      state: observation.state,
      topologyRevision: configuration.topologyRevision.copyWith(
        applied: max(
          previous.topologyRevision.applied,
          incoming.topologyRevision.applied,
        ),
      ),
    );
  }
}

extension TopologyRealmSnapshotProgress on TopologyRealm {
  TopologyRealm reconcileSnapshot(TopologyRealm? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    return configuration.copyWith(
      state: previous.state.updatedAt.isAfter(incoming.state.updatedAt)
          ? previous.state
          : incoming.state,
    );
  }
}

extension TopologyEngineSnapshotProgress on TopologyEngine {
  TopologyEngine reconcileSnapshot(TopologyEngine? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    return configuration.copyWith(
      state: previous.state.updatedAt.isAfter(incoming.state.updatedAt)
          ? previous.state
          : incoming.state,
    );
  }
}
