import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/features/organizations/features/services/presentation/service_header.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

part "services.freezed.dart";
part "services.g.dart";

@freezed
abstract class Service with _$Service {
  const factory Service({
    required skir.RecordId serviceId,
    required String name,
    required List<skir.ServiceRole> roles,
    required DateTime createdAt,
    skir.RecordId? organization,
    skir.ServiceRegistration? registration,
    skir.ServiceState? state,
    skir.RecordId? runsIn,
  }) = _Service;

  const Service._();

  factory Service.fromSkir(skir.Service service) => Service(
    serviceId: service.serviceId,
    name: service.name,
    roles: service.roles.toList(),
    createdAt: service.createdAt,
    organization: service.organization,
    registration: service.registration,
    state: service.state,
    runsIn: service.runsIn,
  );

  skir.Service toSkir() => skir.Service(
    serviceId: serviceId,
    name: name,
    roles: roles,
    createdAt: createdAt,
    organization: organization,
    registration: registration,
    state: state,
    runsIn: runsIn,
  );

  bool get isEngine =>
      roles.any((role) => role is skir.ServiceRole_engineWrapper);

  bool get isRealm =>
      roles.any((role) => role is skir.ServiceRole_realmWrapper);

  String get displayName =>
      name.isNotEmpty ? name.formatted : "Unnamed Service";

  Color get color => switch ((isEngine, isRealm)) {
    (true, true) => Colors.deepPurpleAccent,
    (true, false) => Colors.blueAccent,
    (false, true) => Colors.deepOrangeAccent,
    (false, false) => Colors.grey,
  };

  bool get isOnline {
    if (state?.status == skir.ServiceStatus.offline) return false;
    final seen = lastSeenTime;
    if (seen == null) return false;
    return DateTime.now().difference(seen) < const Duration(minutes: 2);
  }

  DateTime? get lastSeenTime => state?.lastSeen;
  String get lastSeenLabel {
    final seen = lastSeenTime;
    if (seen == null) return "Never";
    final difference = DateTime.now().difference(seen);
    if (difference.inSeconds < 60) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return "${difference.inDays}d ago";
  }

  String get typeLabel => switch ((isEngine, isRealm)) {
    (true, true) => "Engine & Realm",
    (true, false) => "Engine",
    (false, true) => "Realm",
    (false, false) => "Unknown",
  };

  IconData get icon => switch ((isEngine, isRealm)) {
    (true, true) => Icons.dns,
    (true, false) => Icons.memory,
    (false, true) => Icons.cloud,
    (false, false) => Icons.device_unknown,
  };
}

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
        ) => previous.upsertByKey(
          (service) => service.serviceId,
          Service.fromSkir(value),
        ),
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

  Future<void> updateService(Service service) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) throw ApiException.notAuthenticated();
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    state.ensureReady();
    final previousState = state;
    state = AsyncData(
      state.requireValue
          .map(
            (value) => value.serviceId == service.serviceId ? service : value,
          )
          .toList(),
    );
    try {
      final request = skir.UpdateOrganizationServiceRequest(
        serviceId: service.serviceId,
        name: service.name,
      );
      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.services.update",
        skir.UpdateOrganizationServiceRequest.serializer.toBytes(request),
        skir.UpdateOrganizationServiceResponse.serializer,
      );
      switch (response) {
        case skir.UpdateOrganizationServiceResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdateOrganizationServiceResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdateOrganizationServiceResponse_serviceNotFoundErrorWrapper():
          throw ApiException.notFound("Service");
        case skir.UpdateOrganizationServiceResponse_successWrapper():
      }
    } catch (_) {
      state = previousState;
      rethrow;
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

class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.serviceId);
  final skir.RecordId serviceId;
  @override
  String get id => serviceId.id;
  @override
  AsyncValue<Selectable> create(Ref ref) =>
      ref.watch(serviceProvider(serviceId)).whenData((value) {
        if (value == null) throw SelectableNotFoundException(this);
        return ServiceSelectable(ref: ref, id: this, service: value);
      });
  @override
  int get hashCode => serviceId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceIdentifier && other.serviceId == serviceId;
  @override
  String toString() => "ServiceIdentifier(id: $serviceId)";
}

class ServiceSelectable extends Selectable<ServiceIdentifier> {
  ServiceSelectable({
    required this.ref,
    required this.id,
    required this.service,
  });
  @override
  final ServiceIdentifier id;
  final Service service;
  final Ref ref;
  @override
  String get name => service.displayName;
  @override
  ObjectBlueprint get objectBlueprint => ObjectBlueprint(
    fields: {
      "name": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
    },
  );
  @override
  List<SelectableOperation> get operations => [
    if (service.isOnline && service.organization != null)
      OpenSelectableOperation(
        onOpen: () => ref
            .read(appRouterProvider)
            .navigate(
              OrganizationRoute(
                organizationId: service.organization!.id,
                children: [RealmRoute(realmId: service.serviceId.id)],
              ),
            ),
        allowMultiSelect: false,
      ),
    UnbindSelectableOperation(
      onUnbind: () =>
          ref.read(servicesProvider.notifier).deleteService(service.serviceId),
    ),
  ];
  @override
  Widget? header() => ServiceHeader(
    id: service.serviceId.id,
    name: service.displayName,
    color: service.color,
  );
  @override
  dynamic fieldValue(String path) => path == "name" ? service.name : null;
  @override
  void setFieldValue(String path, dynamic value) {
    if (path != "name" || value is! String) {
      throw ArgumentError.value(value, path);
    }
    ref
        .read(servicesProvider.notifier)
        .updateService(service.copyWith(name: value));
  }

  @override
  int get hashCode => Object.hash(id, service);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceSelectable && other.id == id && other.service == service;
}
