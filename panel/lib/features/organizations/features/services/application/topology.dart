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
    yield* ref.watchProjection<
      OrganizationTopology,
      skir.WatchOrganizationTopologyResponse,
      skir.OrganizationTopologyChanged
    >(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.topology.watch",
      eventSubject:
          "cloud.from.organization.${organizationId.id}.topology.watch",
      requestBytes: skir.WatchOrganizationTopologyRequest.serializer.toBytes(
        skir.WatchOrganizationTopologyRequest(),
      ),
      responseSerializer: skir.WatchOrganizationTopologyResponse.serializer,
      eventSerializer: skir.OrganizationTopologyChanged.serializer,
      snapshot: (response) => response.readSnapshot(),
      reduce: (current, event) => event.applyTo(current),
      confirmedEvents: ref
          .watch(resourceRepositoriesProvider)
          .services(organizationId)
          .configurations
          .map(skir.OrganizationTopologyChanged.wrapConfigurationChanged),
      reconcileSnapshot: (current, incoming) =>
          incoming.reconcileSnapshot(current),
      initialValue: OrganizationTopology.empty,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: const ProjectionReconciliation.latest(),
    );
  }

  /// Reloads the authoritative snapshot and replaces the owned subscription.
  void refresh() => ref.invalidateSelf();
}

extension TopologySnapshotReply on skir.WatchOrganizationTopologyResponse {
  OrganizationTopology readSnapshot() => switch (this) {
    skir.WatchOrganizationTopologyResponse_listWrapper(:final value) =>
      OrganizationTopology.fromSkir(value),
    skir.WatchOrganizationTopologyResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationTopologyResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

extension TopologyProjectionChange on skir.OrganizationTopologyChanged {
  OrganizationTopology applyTo(OrganizationTopology current) => switch (this) {
    skir.OrganizationTopologyChanged_replaceWrapper(:final value) =>
      OrganizationTopology.fromSkir(value).reconcileSnapshot(current),
    skir.OrganizationTopologyChanged_configurationChangedWrapper(
      :final value,
    ) =>
      current.applyConfiguration(value),
    skir.OrganizationTopologyChanged_hostUpdatedWrapper(:final value) =>
      current.applyHostObservation(TopologyHost.fromSkir(value)),
    skir.OrganizationTopologyChanged_realmUpdatedWrapper(:final value) =>
      current.applyRealmObservation(TopologyRealm.fromSkir(value)),
    skir.OrganizationTopologyChanged_engineUpdatedWrapper(:final value) =>
      current.applyEngineObservation(TopologyEngine.fromSkir(value)),
    skir.OrganizationTopologyChanged_unknown() =>
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
