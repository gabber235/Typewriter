import "dart:async";

import "package:clock/clock.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
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

    final results = ref
        .watch(resourceRepositoriesProvider)
        .services(organizationId)
        .identities
        .listen((service) {
          if (state.value case final values?) {
            state = AsyncData(_upsertCanonicalService(values, service).values);
          }
        });
    ref.onDispose(results.cancel);
    final request = skir.WatchOrganizationServicesRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${this.organizationId.id}.services.watch",
      listenSubject:
          "cloud.from.organization.${this.organizationId.id}.services.watch",
      requestBytes: skir.WatchOrganizationServicesRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationServicesResponse.serializer,
      transformer: (previous, response) => switch (response) {
        skir.WatchOrganizationServicesResponse_unknown() =>
          throw ApiException.unknownResponseMessage(),
        skir.WatchOrganizationServicesResponse_internalErrorWrapper() =>
          throw ApiException.internalServerError(),
        skir.WatchOrganizationServicesResponse_listWrapper(:final value) =>
          value.map(Service.fromSkir).toList(),
        skir.WatchOrganizationServicesResponse_addWrapper(:final value) ||
        skir.WatchOrganizationServicesResponse_updateWrapper(
          :final value,
        ) => _upsertWatchedService(previous, Service.fromSkir(value)).values,
        skir.WatchOrganizationServicesResponse_removeWrapper(:final value) =>
          previous?.where((service) => service.serviceId != value).toList() ??
              [],
      },
    );
  }

  /// Binds a service registration token to this organization.
  ///
  /// The token is single use and may be expired. A successful bind invalidates
  /// the watch so the backend becomes the source of the new service identity;
  /// invalid tokens are reported as a bad request and uncertain transport
  /// outcomes remain visible to the mutation coordinator.
  Future<void> bindService(String token) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final request = skir.BindServiceRequest(
      operationId: uuid.v4(),
      registrationToken: token,
    );
    final response = await ref.mutateSkir(
      "cloud.to.user.$userId.organization.${this.organizationId.id}.services.bind",
      skir.BindServiceRequest.serializer.toBytes(request),
      skir.BindServiceResponse.serializer,
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      label: "Bind service",
      classify: (response) => switch (response) {
        skir.BindServiceResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.BindServiceResponse_unknown() ||
        skir.BindServiceResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
    );
    switch (response) {
      case skir.BindServiceResponse_invalidOperationIdErrorWrapper():
        throw ApiException.badRequest("Operation identity is required");
      case skir.BindServiceResponse_operationIdentityReusedErrorWrapper():
        throw ApiException.conflict(
          "Operation identity was reused with different input",
        );
      case skir.BindServiceResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.BindServiceResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.BindServiceResponse_invalidRegistrationTokenErrorWrapper():
        throw ApiException.badRequest("Invalid or expired registration token");
      case skir.BindServiceResponse_organizationNotFoundErrorWrapper():
        throw ApiException.notFound("Organization");
      case skir.BindServiceResponse_successWrapper():
        ref.invalidateSelf();
    }
  }

  /// Renames a canonical service identity using its current revision.
  ///
  /// The name is sent as the complete editable identity. A backend conflict
  /// replaces the local canonical value and returns both revisions and the
  /// actual identity value, allowing the editor to recover without guessing.
  Future<TypedMutationResult> updateService(Service service) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    state.ensureReady();
    final request = skir.UpdateOrganizationServiceRequest(
      operationId: uuid.v4(),
      serviceId: service.serviceId,
      expectedRevision: service.revision,
      name: service.name,
    );
    final skir.UpdateOrganizationServiceResponse response;
    try {
      response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${this.organizationId.id}.services.update",
        skir.UpdateOrganizationServiceRequest.serializer.toBytes(request),
        skir.UpdateOrganizationServiceResponse.serializer,
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Update service: ${service.displayName}",
        resources: {(organizationId, service.serviceId)},
        classify: (response) => switch (response) {
          skir.UpdateOrganizationServiceResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.UpdateOrganizationServiceResponse_unknown() ||
          skir.UpdateOrganizationServiceResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );
    } on SubmissionException<skir.UpdateOrganizationServiceResponse> catch (
      error
    ) {
      return error.toMutation(
        (_) async => throw StateError("Service replay is unsupported"),
      );
    }

    switch (response) {
      case skir.UpdateOrganizationServiceResponse_invalidOperationIdErrorWrapper():
        throw ApiException.badRequest("Operation identity is required");
      case skir.UpdateOrganizationServiceResponse_operationIdentityReusedErrorWrapper():
        throw ApiException.conflict(
          "Operation identity was reused with different input",
        );
      case skir.UpdateOrganizationServiceResponse_unknown():
        return unavailableMutation("The server returned an unknown response");
      case skir.UpdateOrganizationServiceResponse_internalErrorWrapper():
        return unavailableMutation("The server could not update the service");
      case skir.UpdateOrganizationServiceResponse_conflictErrorWrapper(
        :final value,
      ):
        final actual = Service.fromSkir(value.actual);
        final upsert = _upsertCanonicalService(state.requireValue, actual);
        state = AsyncData(upsert.values);
        return TypedMutationResult.conflict(
          expectedRevision: value.expectedRevision,
          actualRevision: upsert.canonical.revision,
          actualValue: upsert.canonical.identityValue,
        );
      case skir.UpdateOrganizationServiceResponse_invalidRecordIdErrorWrapper():
        return invalidMutation("The service contains an invalid reference");
      case skir.UpdateOrganizationServiceResponse_serviceNotFoundErrorWrapper():
        return unavailableMutation(
          "The service no longer exists",
          targetDeleted: true,
        );
      case skir.UpdateOrganizationServiceResponse_validationErrorWrapper():
        return invalidMutation("The service contains invalid values");
      case skir.UpdateOrganizationServiceResponse_successWrapper(:final value):
        final updatedService = Service.fromSkir(value);
        final upsert = _upsertCanonicalService(
          state.requireValue,
          updatedService,
        );
        state = AsyncData(upsert.values);
        return TypedMutationResult.success(
          revision: upsert.canonical.revision,
          value: upsert.canonical.identityValue,
        );
    }
  }

  /// Removes the service binding from this organization.
  ///
  /// The local projection removes the service only after the backend confirms
  /// the unbind. A missing service is surfaced as a not found error, while an
  /// uncertain response is left to the mutation coordinator for recovery.
  Future<void> deleteService(skir.RecordId serviceId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    state.ensureReady();
    final removed = state.requireValue.firstWhere(
      (service) => service.serviceId == serviceId,
    );
    final request = skir.UnbindServiceRequest(
      operationId: uuid.v4(),
      serviceId: serviceId.id,
    );
    final response = await ref.mutateSkir(
      "cloud.to.user.$userId.organization.${this.organizationId.id}.services.unbind",
      skir.UnbindServiceRequest.serializer.toBytes(request),
      skir.UnbindServiceResponse.serializer,
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      label: "Unbind service: ${removed.displayName}",
      resources: {(organizationId, serviceId)},
      classify: (response) => switch (response) {
        skir.UnbindServiceResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.UnbindServiceResponse_unknown() ||
        skir.UnbindServiceResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
    );

    switch (response) {
      case skir.UnbindServiceResponse_invalidOperationIdErrorWrapper():
        throw ApiException.badRequest("Operation identity is required");
      case skir.UnbindServiceResponse_operationIdentityReusedErrorWrapper():
        throw ApiException.conflict(
          "Operation identity was reused with different input",
        );
      case skir.UnbindServiceResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.UnbindServiceResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.UnbindServiceResponse_serviceNotFoundErrorWrapper():
        throw ApiException.notFound("Service");
      case skir.UnbindServiceResponse_successWrapper():
        state = AsyncData(
          state.requireValue
              .where((service) => service.serviceId != serviceId)
              .toList(),
        );
    }
  }
}

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.
@riverpod
Future<Service?> canonicalService(Ref ref, skir.RecordId id) async {
  return (await ref.watch(canonicalServicesProvider.future))
      .firstWhereOrNull((service) => service.serviceId == id);
}
