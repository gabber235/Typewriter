part of "services.dart";

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations.
/// Snapshots and configuration changes own child membership. Runtime reports
/// update observed state only and cannot create or revive child resources. A
/// topology entry is therefore not another service identity.
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
    final connection = ref.watch(natsProvider.notifier);
    final projection = skir.WatchOrganizationTopologyRequest()
        .watch<OrganizationTopology>(
          ref,
          userId: userId,
          organizationId: organizationId,
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
          reconciliation: const ProjectionReconciliation.latest(),
        );
    await for (final topology in projection) {
      if (!ref.mounted) return;
      final observed = topology.realmInstances
          .map((realm) => realm.realmId)
          .toSet();
      try {
        await connection.refreshAuthorization(observed);
      } on Object {
        // A failed grant refresh retains the current connection and does not
        // invalidate this topology fact.
      }
      if (!ref.mounted) return;
      yield topology;
    }
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
    skir.OrganizationTopologyChanged_observationsReportedWrapper(
      :final value,
    ) =>
      current.applyRuntimeObservation(value),
    skir.OrganizationTopologyChanged_hostAdvertisedWrapper(:final value) =>
      current.applyAdvertisement(value),
    skir.OrganizationTopologyChanged_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}
