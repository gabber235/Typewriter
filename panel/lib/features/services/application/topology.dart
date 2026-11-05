part of "services.dart";

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with canonical configuration
/// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
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
  Stream<skir.OrganizationTopologySnapshot> build(
    skir.RecordId organizationId,
  ) {
    return ref.watchSignedIn(
      signedOut: skir.OrganizationTopologySnapshot.defaultInstance,
      (userId) => skir.WatchOrganizationTopologyRequest()
          .watch<skir.OrganizationTopologySnapshot>(
            ref,
            userId: userId,
            organizationId: organizationId,
            snapshot: (response) => response.readSnapshot(),
            reduce: (current, event) => event.applyTo(current),
            confirmedEvents: ref
                .watch(serviceResourceRepositoryProvider(organizationId))
                .configurations
                .map(skir.OrganizationTopologyChanged.wrapConfigurationChanged),
            reconcileSnapshot: (current, incoming) =>
                incoming.reconcileSnapshot(current),
            initialValue: skir.OrganizationTopologySnapshot.defaultInstance,
            reconciliation: const ProjectionReconciliation.latest(),
          ),
    );
  }

  /// Reloads the authoritative snapshot and replaces the owned subscription.
  void refresh() => ref.invalidateSelf();
}

extension TopologySnapshotReply on skir.WatchOrganizationTopologyResponse {
  skir.OrganizationTopologySnapshot readSnapshot() => switch (this) {
    skir.WatchOrganizationTopologyResponse_listWrapper(:final value) => value,
    skir.WatchOrganizationTopologyResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationTopologyResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

extension TopologyProjectionChange on skir.OrganizationTopologyChanged {
  skir.OrganizationTopologySnapshot applyTo(
    skir.OrganizationTopologySnapshot current,
  ) => switch (this) {
    skir.OrganizationTopologyChanged_replaceWrapper(:final value) =>
      value.reconcileSnapshot(current),
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
