part of "services.dart";

@freezed
abstract class OrganizationTopology with _$OrganizationTopology {
  const factory OrganizationTopology({
    required List<skir.ServiceHost> hosts,
    required List<skir.RealmInstance> realmInstances,
    required List<skir.EngineInstance> engineInstances,
  }) = _OrganizationTopology;

  const OrganizationTopology._();

  static const empty = OrganizationTopology(
    hosts: [],
    realmInstances: [],
    engineInstances: [],
  );

  skir.RealmInstance? realmOwnedBy(skir.RecordId hostId) {
    for (final realm in realmInstances) {
      if (realm.ownerHostId == hostId) return realm;
    }
    return null;
  }

  skir.EngineInstance? engineOwnedBy(skir.RecordId hostId) {
    for (final engine in engineInstances) {
      if (engine.ownerHostId == hostId) return engine;
    }
    return null;
  }
}

@riverpod
class OrganizationTopologyStream extends _$OrganizationTopologyStream {
  @override
  Stream<OrganizationTopology> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    final organizationId = ref.watch(organizationIdProvider);
    if (userId == null || organizationId == null) {
      yield OrganizationTopology.empty;
      return;
    }

    final request = skir.WatchOrganizationTopologyRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.topology.watch",
      listenSubject: "cloud.from.organization.${organizationId.id}.topology",
      requestBytes: skir.WatchOrganizationTopologyRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationTopologyResponse.serializer,
      transformer: _reduceTopology,
    );
  }

  Future<void> configureHost({
    required skir.ServiceHost host,
    required skir.HostExecutionConfiguration execution,
  }) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    final request = skir.ConfigureServiceHostRequest(
      hostId: host.hostId,
      expectedRevision: host.revision,
      execution: execution,
    );
    final response = await ref.requestSkir(
      "cloud.to.user.$userId.organization.${organizationId.id}.topology.configure",
      skir.ConfigureServiceHostRequest.serializer.toBytes(request),
      skir.ConfigureServiceHostResponse.serializer,
    );
    switch (response) {
      case skir.ConfigureServiceHostResponse_successWrapper():
        return;
      case skir.ConfigureServiceHostResponse_conflictErrorWrapper():
        throw ApiException.conflict(
          "The host changed while it was being configured",
        );
      case skir.ConfigureServiceHostResponse_invalidConfigurationErrorWrapper(
        :final value,
      ):
        throw ApiException.badRequest(value.message);
      case skir.ConfigureServiceHostResponse_incompatibleEngineErrorWrapper():
        throw ApiException.badRequest(
          "The selected engine is not supported by this host",
        );
      case skir.ConfigureServiceHostResponse_realmNotFoundErrorWrapper():
        throw ApiException.notFound("Realm");
      case skir.ConfigureServiceHostResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.ConfigureServiceHostResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }
}

OrganizationTopology _reduceTopology(
  OrganizationTopology? previous,
  skir.WatchOrganizationTopologyResponse response,
) {
  final current = previous ?? OrganizationTopology.empty;
  return switch (response) {
    skir.WatchOrganizationTopologyResponse_listWrapper(:final value) =>
      OrganizationTopology(
        hosts: value.hosts.toList(),
        realmInstances: value.realms.toList(),
        engineInstances: value.engines.toList(),
      ),
    skir.WatchOrganizationTopologyResponse_hostUpdatedWrapper(:final value) =>
      current.copyWith(
        hosts: _upsertById(current.hosts, value, (it) => it.hostId),
      ),
    skir.WatchOrganizationTopologyResponse_realmUpdatedWrapper(:final value) =>
      current.copyWith(
        realmInstances: _upsertById(
          current.realmInstances,
          value,
          (it) => it.realmId,
        ),
      ),
    skir.WatchOrganizationTopologyResponse_engineUpdatedWrapper(:final value) =>
      current.copyWith(
        engineInstances: _upsertById(
          current.engineInstances,
          value,
          (it) => it.engineId,
        ),
      ),
    skir.WatchOrganizationTopologyResponse_resourceRemovedWrapper(
      :final value,
    ) =>
      current.copyWith(
        hosts: current.hosts.where((it) => it.hostId != value).toList(),
        realmInstances: current.realmInstances
            .where((it) => it.realmId != value)
            .toList(),
        engineInstances: current.engineInstances
            .where((it) => it.engineId != value)
            .toList(),
      ),
    skir.WatchOrganizationTopologyResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationTopologyResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

List<Value> _upsertById<Value>(
  List<Value> values,
  Value incoming,
  skir.RecordId Function(Value) idOf,
) {
  final index = values.indexWhere((value) => idOf(value) == idOf(incoming));
  if (index == -1) return [...values, incoming];
  final next = values.toList();
  next[index] = incoming;
  return next;
}
