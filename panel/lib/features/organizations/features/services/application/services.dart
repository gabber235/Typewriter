import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "services.freezed.dart";
part "services.g.dart";
part "service_models.dart";
part "service_resource_repository.dart";
part "host_editor_resource.dart";
part "service_editor_resource.dart";
part "service_route_projection.dart";
part "service_connections.dart";
part "service_portable_presentation.dart";
part "service_inspector_layout.dart";
part "topology_portable_presentation.dart";
part "service_selection.dart";
part "topology_models.dart";
part "topology.dart";
part "topology_configuration.dart";
part "host_configuration_types.dart";
part "host_configuration_value.dart";
part "topology_selection.dart";
part "topology_host_selection.dart";
part "topology_runtime_selection.dart";

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use operation identities and optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.
@riverpod
class CanonicalOrganizationServices extends _$CanonicalOrganizationServices {
  @override
  Stream<List<Service>> build(skir.RecordId organizationId) async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationServicesRequest();
    yield* ref.watchProjection<
      List<Service>,
      skir.WatchOrganizationServicesResponse,
      skir.OrganizationServicesChanged
    >(
      subject:
          "cloud.to.user.$userId.organization.${this.organizationId.id}.services.watch",
      eventSubject:
          "cloud.from.organization.${this.organizationId.id}.services.watch",
      requestBytes: skir.WatchOrganizationServicesRequest.serializer.toBytes(
        request,
      ),
      responseSerializer: skir.WatchOrganizationServicesResponse.serializer,
      eventSerializer: skir.OrganizationServicesChanged.serializer,
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
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: const ProjectionReconciliation.latest(),
    );
  }
}

extension ServiceSnapshotReply on skir.WatchOrganizationServicesResponse {
  List<Service> readSnapshot() => switch (this) {
    skir.WatchOrganizationServicesResponse_listWrapper(:final value) =>
      value.map(Service.fromSkir).toList(),
    skir.WatchOrganizationServicesResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationServicesResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

extension ServiceProjectionChange on skir.OrganizationServicesChanged {
  List<Service> applyWatched(List<Service> current) => _apply(
    current,
    (values, incoming) => _upsertWatchedService(values, incoming).values,
  );

  List<Service> applyCanonical(List<Service> current) => _apply(
    current,
    (values, incoming) => _upsertCanonicalService(values, incoming).values,
  );

  List<Service> _apply(
    List<Service> current,
    List<Service> Function(List<Service>, Service) update,
  ) => switch (this) {
    skir.OrganizationServicesChanged_replaceWrapper(:final value) =>
      value.map(Service.fromSkir).toList().reconcileSnapshot(current),
    skir.OrganizationServicesChanged_updateWrapper(:final value) => update(
      current,
      Service.fromSkir(value),
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
Future<Service?> canonicalService(Ref ref, skir.RecordId id) async {
  return (await ref.watch(canonicalServicesProvider.future))
      .firstWhereOrNull((service) => service.serviceId == id);
}

/// Replacement membership is authoritative, while surviving identities retain
/// newer accepted revisions and heartbeat observations.
extension ServiceSnapshotReconciliation on List<Service> {
  List<Service> reconcileSnapshot(List<Service> previous) => [
    for (final incoming in this)
      incoming.reconcileSnapshot(
        previous.firstWhereOrNull(
          (item) => item.serviceId == incoming.serviceId,
        ),
      ),
  ];
}

extension ServiceSnapshotProgress on Service {
  Service reconcileSnapshot(Service? previous) {
    final incoming = this;
    if (previous == null) return incoming;
    final identity = _upsertWatchedService([previous], incoming).canonical;
    final previousState = previous.state;
    final incomingState = incoming.state;
    final observation =
        previousState != null &&
            (incomingState == null ||
                previousState.lastSeen.isAfter(incomingState.lastSeen))
        ? previousState
        : incomingState;
    return identity.copyWith(state: observation);
  }
}
