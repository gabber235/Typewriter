import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "host_configuration_editing.dart";
part "host_configuration_types.dart";
part "host_configuration_value.dart";
part "service_connections.dart";
part "service_identity_editing.dart";
part "service_inspector_layout.dart";
part "service_portable_presentation.dart";
part "service_projection.dart";
part "service_resource_repository.dart";
part "service_route_projection.dart";
part "service_selection.dart";
part "services.freezed.dart";
part "services.g.dart";
part "topology.dart";
part "topology_configuration.dart";
part "topology_host_selection.dart";
part "topology_portable_presentation.dart";
part "topology_projection.dart";
part "topology_runtime_selection.dart";
part "topology_selection.dart";

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.
@riverpod
class CanonicalOrganizationServices extends _$CanonicalOrganizationServices {
  @override
  Stream<List<skir.Service>> build(skir.RecordId organizationId) async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    yield* skir.WatchOrganizationServicesRequest().watch(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) => response.readSnapshot(),
      reduce: (current, event) => event.applyWatched(current),
      confirmedEvents: ref
          .watch(resourceRepositoriesProvider)
          .services(organizationId)
          .identities,
      reduceConfirmed: (current, event) => event.applyCanonical(current),
      reconcileSnapshot: (current, incoming) =>
          incoming.reconcileSnapshot(current),
      initialValue: const [],
      reconciliation: const ProjectionReconciliation.latest(),
    );
  }
}

extension ServiceSnapshotReply on skir.WatchOrganizationServicesResponse {
  List<skir.Service> readSnapshot() => switch (this) {
    skir.WatchOrganizationServicesResponse_listWrapper(:final value) =>
      value.map((service) => service.requireKnown()).toList(),
    skir.WatchOrganizationServicesResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationServicesResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

extension ServiceProjectionChange on skir.OrganizationServicesChanged {
  List<skir.Service> applyWatched(List<skir.Service> current) => _apply(
    current,
    (values, incoming) => values.reconcileWatched(incoming).values,
  );

  List<skir.Service> applyCanonical(List<skir.Service> current) => _apply(
    current,
    (values, incoming) => values.reconcileCanonical(incoming).values,
  );

  List<skir.Service> _apply(
    List<skir.Service> current,
    List<skir.Service> Function(List<skir.Service>, skir.Service) update,
  ) => switch (this) {
    skir.OrganizationServicesChanged_replaceWrapper(:final value) =>
      value
          .map((service) => service.requireKnown())
          .toList()
          .reconcileSnapshot(current),
    skir.OrganizationServicesChanged_updateWrapper(:final value) => update(
      current,
      value.requireKnown(),
    ),
    skir.OrganizationServicesChanged_removeWrapper(:final value) =>
      current.where((service) => service.serviceId != value).toList(),
    skir.OrganizationServicesChanged_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.
@riverpod
Future<skir.Service?> canonicalService(Ref ref, skir.RecordId id) async {
  return (await ref.watch(canonicalServicesProvider.future))
      .firstWhereOrNull((service) => service.serviceId == id);
}

/// Replacement membership is authoritative, while surviving identities retain
/// newer accepted revisions and heartbeat observations.
extension ServiceSnapshotReconciliation on List<skir.Service> {
  List<skir.Service> reconcileSnapshot(List<skir.Service> previous) => [
    for (final incoming in this)
      incoming.reconcileSnapshot(
        previous.firstWhereOrNull(
          (item) => item.serviceId == incoming.serviceId,
        ),
      ),
  ];
}

extension ServiceSnapshotProgress on skir.Service {
  skir.Service reconcileSnapshot(skir.Service? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final identity = [previous].reconcileWatched(incoming).canonical;
    final previousState = previous.state;
    final incomingState = incoming.state;
    final observation =
        previousState != null &&
            (incomingState == null ||
                previousState.lastSeen.isAfter(incomingState.lastSeen))
        ? previousState
        : incomingState;
    return identity.withState(observation);
  }
}
