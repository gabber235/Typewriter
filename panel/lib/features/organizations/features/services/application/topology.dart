part of "services.dart";

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations;
/// child realm and engine entries describe the resources currently reported by
/// that host. A topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.
@riverpod
class OrganizationTopologyController extends _$OrganizationTopologyController {
  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) async* {
    final userId = await ref.watch(userIdProvider.future);
    if (!ref.mounted) return;
    if (userId == null) {
      yield OrganizationTopology.empty;
      return;
    }
    final results = ref
        .watch(resourceRepositoriesProvider)
        .services(organizationId)
        .configurations
        .listen((change) {
          state = AsyncData(
            (state.value ?? OrganizationTopology.empty).applyConfiguration(
              change,
            ),
          );
        });
    ref.onDispose(results.cancel);
    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.topology.watch",
      listenSubject:
          "cloud.from.organization.${organizationId.id}.topology.watch",
      requestBytes: skir.WatchOrganizationTopologyRequest.serializer.toBytes(
        skir.WatchOrganizationTopologyRequest(),
      ),
      serializer: skir.WatchOrganizationTopologyResponse.serializer,
      transformer: (_, response) => _reduceTopology(state.value, response),
    );
  }

  /// Reloads the authoritative snapshot and replaces the owned subscription.
  void refresh() => ref.invalidateSelf();

  /// Applies one complete host execution configuration with optimistic
  /// concurrency.
  ///
  /// The backend result is the canonical configuration result. On success it
  /// is integrated into this projection before being returned. On conflict,
  /// the actual backend configuration is integrated before the conflict is
  /// reported, allowing the editor to refresh its revision. A successful
  /// result describes desired configuration and observed resources; it does
  /// not guarantee that reconciliation has completed.
  Future<TopologyConfigurationResult> configureHost({
    required TopologyHost host,
    required skir.HostExecutionConfiguration execution,
  }) async {
    var active = true;
    final stop = ref.onDispose(() => active = false);
    try {
      final userId = await ref.read(userIdProvider.future);
      if (userId == null) throw ApiException.notAuthenticated();
      if (!active) throw ApiException.notAuthenticated();
      state.ensureReady();
      final request = skir.ConfigureServiceHostRequest(
        operationId: uuid.v4(),
        hostId: host.hostId,
        expectedRevision: host.revision,
        execution: execution,
      );
      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${this.organizationId.id}.topology.configure",
        skir.ConfigureServiceHostRequest.serializer.toBytes(request),
        skir.ConfigureServiceHostResponse.serializer,
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Apply Host configuration: ${host.hostId.id}",
        resources: {(organizationId, host.hostId)},
        classify: (response) => switch (response) {
          skir.ConfigureServiceHostResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.ConfigureServiceHostResponse_unknown() ||
          skir.ConfigureServiceHostResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.ConfigureServiceHostResponse_successWrapper(:final value):
          if (active) {
            state = AsyncData(
              (state.value ?? OrganizationTopology.empty).applyConfiguration(
                value,
              ),
            );
          }
          return TopologyConfigurationResult.fromSkir(value);
        case skir.ConfigureServiceHostResponse_conflictErrorWrapper(
          :final value,
        ):
          if (active) {
            state = AsyncData(
              (state.value ?? OrganizationTopology.empty).applyConfiguration(
                value.actual,
              ),
            );
          }
          throw _HostConfigurationConflict(
            TopologyConfigurationResult.fromSkir(value.actual),
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
        case skir.ConfigureServiceHostResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.ConfigureServiceHostResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.ConfigureServiceHostResponse_invalidOperationIdErrorWrapper():
          throw ApiException.badRequest("Operation identity is required");
        case skir.ConfigureServiceHostResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.ConfigureServiceHostResponse_unknown():
          throw ApiException.unknownResponseMessage();
      }
    } finally {
      stop();
    }
  }
}

class _HostConfigurationConflict implements Exception {
  const _HostConfigurationConflict(this.actual);

  final TopologyConfigurationResult actual;
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
    skir.WatchOrganizationTopologyResponse_configurationChangedWrapper(
      :final value,
    ) =>
      current.applyConfiguration(value),
    skir.WatchOrganizationTopologyResponse_hostUpdatedWrapper(:final value) =>
      current.applyHostObservation(TopologyHost.fromSkir(value)),
    skir.WatchOrganizationTopologyResponse_realmUpdatedWrapper(:final value) =>
      current.applyRealmObservation(TopologyRealm.fromSkir(value)),
    skir.WatchOrganizationTopologyResponse_engineUpdatedWrapper(:final value) =>
      current.applyEngineObservation(TopologyEngine.fromSkir(value)),
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
