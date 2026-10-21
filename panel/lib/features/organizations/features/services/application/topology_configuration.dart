part of "services.dart";

/// Applies topology watch and mutation changes to the controller's owned
/// immutable projection.
///
/// Configuration changes update the desired and applied revision view and
/// replace the affected child resources. Observations update runtime state and
/// the host's applied revision. Timestamp and revision checks prevent older data
/// from erasing newer knowledge when responses and watch events overlap.
extension OrganizationTopologyConfiguration
    on skir.OrganizationTopologySnapshot {
  /// Uses incoming snapshot membership and retains accepted configuration and
  /// runtime progress only for resources that remain present.
  skir.OrganizationTopologySnapshot reconcileSnapshot(
    skir.OrganizationTopologySnapshot previous,
  ) => _with(
    hosts: [
      for (final incoming in hosts)
        incoming.reconcileSnapshot(
          previous.hosts.firstWhereOrNull(
            (item) => item.hostId == incoming.hostId,
          ),
        ),
    ],
    realms: [
      for (final incoming in this.realms)
        incoming.reconcileSnapshot(
          previous.realms.firstWhereOrNull(
            (item) => item.realmId == incoming.realmId,
          ),
        ),
    ],
    engines: [
      for (final incoming in engines)
        incoming.reconcileSnapshot(
          previous.engines.firstWhereOrNull(
            (item) => item.engineId == incoming.engineId,
          ),
        ),
    ],
  );

  /// Merges a host runtime observation, retaining an existing host's desired
  /// configuration. An unknown host is inserted with the full observed record.
  skir.OrganizationTopologySnapshot applyHostObservation(
    skir.ServiceHost incoming,
  ) {
    final previous = hosts.firstWhereOrNull(
      (host) => host.hostId == incoming.hostId,
    );
    if (previous == null) return _with(hosts: [...hosts, incoming]);
    if (incoming.state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return _with(
      hosts: hosts.toList().upsertByKey(
        (host) => host.hostId,
        previous.withObservation(
          incoming.state,
          applied: incoming.topologyRevision.applied,
        ),
      ),
    );
  }

  /// Merges a realm runtime observation owned by a host.
  skir.OrganizationTopologySnapshot applyRealmObservation(
    skir.RecordId realmId,
    skir.ChildRuntimeState state,
  ) {
    final previous = this.realms.firstWhereOrNull(
      (realm) => realm.realmId == realmId,
    );
    if (previous == null ||
        state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return _with(
      realms: this.realms.toList().upsertByKey(
        (realm) => realm.realmId,
        previous.withState(state),
      ),
    );
  }

  /// Merges an engine runtime observation owned by a host.
  skir.OrganizationTopologySnapshot applyEngineObservation(
    skir.RecordId engineId,
    skir.ChildRuntimeState state,
  ) {
    final previous = engines.firstWhereOrNull(
      (engine) => engine.engineId == engineId,
    );
    if (previous == null ||
        state.updatedAt.isBefore(previous.state.updatedAt)) {
      return this;
    }
    return _with(
      engines: engines.toList().upsertByKey(
        (engine) => engine.engineId,
        previous.withState(state),
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
  skir.OrganizationTopologySnapshot applyConfiguration(
    skir.HostConfigurationChange change,
  ) {
    var host = change.host;
    final previousHost = hosts.firstWhereOrNull(
      (item) => item.hostId == host.hostId,
    );
    if (previousHost != null) {
      if (previousHost.revision > host.revision) return this;
      if (previousHost.state.updatedAt.isAfter(host.state.updatedAt)) {
        host = host.withObservation(
          previousHost.state,
          applied: previousHost.topologyRevision.applied,
        );
      }
    }
    final removed = change.removedResources.toSet();
    var realms = this.realms
        .where(
          (item) =>
              !removed.contains(item.realmId) &&
              (item.ownerHost.id != host.hostId ||
                  item.realmId == change.realm?.realmId),
        )
        .toList();
    var engines = this.engines
        .where(
          (item) =>
              !removed.contains(item.engineId) &&
              (item.ownerHost.id != host.hostId ||
                  item.engineId == change.engine?.engineId),
        )
        .toList();

    if (change.realm case final value?) {
      var realm = value;
      final previous = realms.firstWhereOrNull(
        (item) => item.realmId == realm.realmId,
      );
      if (previous != null &&
          previous.state.updatedAt.isAfter(realm.state.updatedAt)) {
        realm = realm.withState(previous.state);
      }
      realms = realms.upsertByKey((item) => item.realmId, realm);
    }
    if (change.engine case final value?) {
      var engine = value;
      final previous = engines.firstWhereOrNull(
        (item) => item.engineId == engine.engineId,
      );
      if (previous != null &&
          previous.state.updatedAt.isAfter(engine.state.updatedAt)) {
        engine = engine.withState(previous.state);
      }
      engines = engines.upsertByKey((item) => item.engineId, engine);
    }
    return _with(
      hosts: hosts.toList().upsertByKey((item) => item.hostId, host),
      realms: realms,
      engines: engines,
    );
  }

  /// Applies one compound runtime report as one immutable projection update.
  skir.OrganizationTopologySnapshot applyRuntimeObservation(
    skir.HostExecutionObservation observation,
  ) {
    var next = applyHostObservation(observation.host);
    if (observation.realm case final observed?) {
      next = next.applyRealmObservation(observed.realmId, observed.state);
    }
    if (observation.engine case final observed?) {
      next = next.applyEngineObservation(observed.engineId, observed.state);
    }
    return next;
  }

  /// Accepts host discovery without treating it as child membership authority.
  skir.OrganizationTopologySnapshot applyAdvertisement(
    skir.ServiceHost advertisement,
  ) {
    final previous = hosts.firstWhereOrNull(
      (host) => host.hostId == advertisement.hostId,
    );
    final accepted = advertisement.reconcileSnapshot(previous);
    return _with(
      hosts: hosts.toList().upsertByKey((host) => host.hostId, accepted),
    );
  }

  skir.OrganizationTopologySnapshot _with({
    List<skir.ServiceHost>? hosts,
    List<skir.RealmInstance>? realms,
    List<skir.EngineInstance>? engines,
  }) {
    final next = toMutable();
    if (hosts != null) next.hosts = hosts;
    if (realms != null) next.realms = realms;
    if (engines != null) next.engines = engines;
    return next.toFrozen();
  }
}

extension TopologyHostSnapshotProgress on skir.ServiceHost {
  skir.ServiceHost reconcileSnapshot(skir.ServiceHost? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    final observation =
        previous.state.updatedAt.isAfter(incoming.state.updatedAt)
        ? previous
        : incoming;
    return configuration.withObservation(
      observation.state,
      applied: max(
        previous.topologyRevision.applied,
        incoming.topologyRevision.applied,
      ),
    );
  }

  /// Returns this host configuration carrying a host runtime observation and
  /// the configuration revision that observation reports as applied.
  skir.ServiceHost withObservation(
    skir.HostRuntimeState state, {
    required int applied,
  }) =>
      (toMutable()
            ..state = state
            ..mutableTopologyRevision.applied = applied)
          .toFrozen();
}

extension TopologyRealmSnapshotProgress on skir.RealmInstance {
  skir.RealmInstance reconcileSnapshot(skir.RealmInstance? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    return configuration.withState(
      previous.state.updatedAt.isAfter(incoming.state.updatedAt)
          ? previous.state
          : incoming.state,
    );
  }

  skir.RealmInstance withState(skir.ChildRuntimeState state) =>
      (toMutable()..state = state).toFrozen();
}

extension TopologyEngineSnapshotProgress on skir.EngineInstance {
  skir.EngineInstance reconcileSnapshot(skir.EngineInstance? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final configuration = previous.revision > incoming.revision
        ? previous
        : incoming;
    return configuration.withState(
      previous.state.updatedAt.isAfter(incoming.state.updatedAt)
          ? previous.state
          : incoming.state,
    );
  }

  skir.EngineInstance withState(skir.ChildRuntimeState state) =>
      (toMutable()..state = state).toFrozen();
}
