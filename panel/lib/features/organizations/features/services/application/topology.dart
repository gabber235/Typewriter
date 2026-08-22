part of "services.dart";

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

  /// Applies one complete execution configuration with optimistic concurrency.
  ///
  /// The canonical backend result is returned so editor callers can adopt its
  /// revision immediately. Protocol failures are translated to [ApiException]
  /// and do not mutate the watched topology locally.
  Future<TopologyConfigurationResult> configureHost({
    required TopologyHost host,
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
      case skir.ConfigureServiceHostResponse_successWrapper(:final value):
        return TopologyConfigurationResult.fromSkir(value);
      case skir.ConfigureServiceHostResponse_conflictErrorWrapper(:final value):
        throw _HostConfigurationConflict(TopologyHost.fromSkir(value.actual));
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
      case skir.ConfigureServiceHostResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.ConfigureServiceHostResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.ConfigureServiceHostResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }
}

class _HostConfigurationConflict implements Exception {
  const _HostConfigurationConflict(this.actual);

  final TopologyHost actual;
}

OrganizationTopology _reduceTopology(
  OrganizationTopology? previous,
  skir.WatchOrganizationTopologyResponse response,
) {
  final current = previous ?? OrganizationTopology.empty;
  return switch (response) {
    skir.WatchOrganizationTopologyResponse_listWrapper(:final value) =>
      OrganizationTopology(
        hosts: value.hosts.map(TopologyHost.fromSkir).toList(),
        realmInstances: value.realms.map(TopologyRealm.fromSkir).toList(),
        engineInstances: value.engines.map(TopologyEngine.fromSkir).toList(),
      ),
    skir.WatchOrganizationTopologyResponse_hostUpdatedWrapper(:final value) =>
      current.copyWith(
        hosts: _upsertById(
          current.hosts,
          TopologyHost.fromSkir(value),
          (it) => it.hostId,
        ),
      ),
    skir.WatchOrganizationTopologyResponse_realmUpdatedWrapper(:final value) =>
      current.copyWith(
        realmInstances: _upsertById(
          current.realmInstances,
          TopologyRealm.fromSkir(value),
          (it) => it.realmId,
        ),
      ),
    skir.WatchOrganizationTopologyResponse_engineUpdatedWrapper(:final value) =>
      current.copyWith(
        engineInstances: _upsertById(
          current.engineInstances,
          TopologyEngine.fromSkir(value),
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
