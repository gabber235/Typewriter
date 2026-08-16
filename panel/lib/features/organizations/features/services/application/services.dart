import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "services.freezed.dart";
part "services.g.dart";
part "service_models.dart";
part "service_collection.dart";
part "service_inspector_presentation.dart";
part "service_selection.dart";

@riverpod
class Services extends _$Services {
  @override
  Stream<List<Service>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    final organizationId = ref.watch(organizationIdProvider);
    if (userId == null || organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationServicesRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.services.watch",
      listenSubject:
          "cloud.from.organization.${organizationId.id}.services.watch",
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
        ) => _upsertCanonicalService(previous, Service.fromSkir(value)).values,
        skir.WatchOrganizationServicesResponse_removeWrapper(:final value) =>
          previous?.where((service) => service.serviceId != value).toList() ??
              [],
      },
    );
  }

  Future<void> bindService(String token) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    final request = skir.BindServiceRequest(registrationToken: token);
    final response = await ref.requestSkir(
      "cloud.to.user.$userId.organization.${organizationId.id}.services.bind",
      skir.BindServiceRequest.serializer.toBytes(request),
      skir.BindServiceResponse.serializer,
    );
    switch (response) {
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

  Future<TypedMutationResult> updateService(Service service) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    state.ensureReady();
    try {
      final request = skir.UpdateOrganizationServiceRequest(
        serviceId: service.serviceId,
        expectedRevision: service.revision,
        name: service.name,
        runsIn: service.runsIn,
      );
      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.services.update",
        skir.UpdateOrganizationServiceRequest.serializer.toBytes(request),
        skir.UpdateOrganizationServiceResponse.serializer,
      );
      switch (response) {
        case skir.UpdateOrganizationServiceResponse_unknown():
          return _serviceUpdateUnavailable(
            "The server returned an unknown response",
          );
        case skir.UpdateOrganizationServiceResponse_internalErrorWrapper():
          return _serviceUpdateUnavailable(
            "The server could not update the service",
          );
        case skir.UpdateOrganizationServiceResponse_conflictErrorWrapper(
          :final value,
        ):
          final actual = Service.fromSkir(value.actual);
          final upsert = _upsertCanonicalService(state.requireValue, actual);
          state = AsyncData(upsert.values);
          return TypedMutationResult.conflict(
            expectedRevision: value.expectedRevision,
            actualRevision: upsert.canonical.revision,
            actualValue: upsert.canonical.inspectorValue,
          );
        case skir.UpdateOrganizationServiceResponse_invalidRecordIdErrorWrapper():
          return _serviceUpdateInvalid(
            "The service contains an invalid reference",
          );
        case skir.UpdateOrganizationServiceResponse_serviceNotFoundErrorWrapper():
          return _serviceUpdateUnavailable(
            "The service no longer exists",
            targetDeleted: true,
          );
        case skir.UpdateOrganizationServiceResponse_runsInNotFoundErrorWrapper():
          return _serviceUpdateInvalid(
            "The selected Realm service no longer exists",
          );
        case skir.UpdateOrganizationServiceResponse_validationErrorWrapper():
          return _serviceUpdateInvalid("The service contains invalid values");
        case skir.UpdateOrganizationServiceResponse_successWrapper(
          :final value,
        ):
          final updatedService = Service.fromSkir(value);
          final upsert = _upsertCanonicalService(
            state.requireValue,
            updatedService,
          );
          state = AsyncData(upsert.values);
          return TypedMutationResult.success(
            revision: upsert.canonical.revision,
            value: upsert.canonical.inspectorValue,
          );
      }
    } on Object catch (_) {
      return _serviceUpdateUnavailable(
        "The service update could not be completed",
      );
    }
  }

  Future<void> deleteService(skir.RecordId serviceId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    state.ensureReady();
    final previousState = state;
    state = AsyncData(
      state.requireValue
          .where((service) => service.serviceId != serviceId)
          .toList(),
    );
    try {
      final request = skir.UnbindServiceRequest(serviceId: serviceId.id);
      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.services.unbind",
        skir.UnbindServiceRequest.serializer.toBytes(request),
        skir.UnbindServiceResponse.serializer,
      );
      switch (response) {
        case skir.UnbindServiceResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UnbindServiceResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UnbindServiceResponse_serviceNotFoundErrorWrapper():
          throw ApiException.notFound("Service");
        case skir.UnbindServiceResponse_successWrapper():
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }
}

@riverpod
Future<Service?> service(Ref ref, skir.RecordId id) async => (await ref.watch(
  servicesProvider.future,
)).firstWhereOrNull((service) => service.serviceId == id);

TypedMutationResult _serviceUpdateInvalid(String message) =>
    TypedMutationResult.invalid([
      TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
    ]);

TypedMutationResult _serviceUpdateUnavailable(
  String message, {
  bool targetDeleted = false,
}) => TypedMutationResult.unavailable([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: message,
    details: targetDeleted
        ? const [TypeDiagnosticDetail(key: "editor.target", value: "deleted")]
        : const [],
  ),
]);
