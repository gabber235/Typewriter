import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/api/service/registration.pb.dart"
    hide ServiceStatus;
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/organization/services/service_header.dart";

part "services.g.dart";

@riverpod
class Services extends _$Services {
  @override
  Stream<List<Service>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = ListOrganizationServicesRequest();
    final stream = ref.requestProtoThenListen(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.services.list",
      listenSubject: "cloud.in.organization.$organizationId.services.list",
      request: request,
      responseBuilder: ListOrganizationServicesResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.services.services.toList();
    }
  }

  Future<void> bindService(String token) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    final request = BindServiceRequest()..registrationToken = token;
    final response = await ref
        .read(natsProvider)
        .requestProto(
          "cloud.out.user.$userId.organization.$organizationId.services.bind",
          request,
          BindServiceResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
  }

  Future<void> updateService(Service service) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    final previousState = state;

    final currentState = state.value ?? [];
    state = AsyncData(
      currentState.map((s) => s.id == service.id ? service : s).toList(),
    );

    try {
      final request = UpdateServiceRequest()
        ..serviceId = service.id
        ..name = service.name;
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.services.update",
            request,
            UpdateServiceResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    final previousState = state;

    state = AsyncData(
      state.requireValue.where((s) => s.id != serviceId).toList(),
    );

    try {
      final request = UnbindServiceRequest()..serviceId = serviceId;
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.services.unbind",
            request,
            UnbindServiceResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

@riverpod
Future<Service?> service(Ref ref, String id) async {
  final services = await ref.watch(servicesProvider.future);
  return services.firstWhereOrNull((service) => service.id == id);
}

extension ServiceExtension on Service {
  String get displayName =>
      name.isNotEmpty ? name.formatted : "Unnamed Service";

  Color get color {
    Color base;
    if (serviceTypes.contains(ServiceType.SERVICE_TYPE_ENGINE) &&
        serviceTypes.contains(ServiceType.SERVICE_TYPE_REALM)) {
      base = Colors.deepPurpleAccent;
    } else if (serviceTypes.contains(ServiceType.SERVICE_TYPE_ENGINE)) {
      base = Colors.blueAccent;
    } else if (serviceTypes.contains(ServiceType.SERVICE_TYPE_REALM)) {
      base = Colors.deepOrangeAccent;
    } else {
      base = Colors.grey;
    }
    return base;
  }

  bool get isOnline {
    if (!hasState()) return false;

    if (state.status == ServiceStatus.SERVICE_STATUS_OFFLINE) {
      return false;
    }

    if (!state.hasLastSeen()) return false;
    final now = DateTime.now();
    final lastSeenTime = state.lastSeen.toDateTime();
    return now.difference(lastSeenTime).inMinutes < 2;
  }

  DateTime? get lastSeenTime {
    if (!hasState() || !state.hasLastSeen()) return null;
    return state.lastSeen.toDateTime();
  }

  String get lastSeenLabel {
    if (!hasState() || !state.hasLastSeen()) return "Never";
    final now = DateTime.now();
    final difference = now.difference(lastSeenTime!);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }

  String get typeLabel {
    if (serviceTypes.isEmpty) return "Unknown";
    return serviceTypes
        .map((t) {
          switch (t) {
            case ServiceType.SERVICE_TYPE_ENGINE:
              return "Engine";
            case ServiceType.SERVICE_TYPE_REALM:
              return "Realm";
            default:
              return "Unknown";
          }
        })
        .join(" & ");
  }

  IconData get icon {
    if (serviceTypes.contains(ServiceType.SERVICE_TYPE_ENGINE) &&
        serviceTypes.contains(ServiceType.SERVICE_TYPE_REALM)) {
      return Icons.dns;
    }
    if (serviceTypes.contains(ServiceType.SERVICE_TYPE_ENGINE)) {
      return Icons.memory;
    }
    if (serviceTypes.contains(ServiceType.SERVICE_TYPE_REALM)) {
      return Icons.cloud;
    }
    return Icons.device_unknown;
  }
}

class ServiceIdentifier extends SelectableIdentifier {
  ServiceIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncService = ref.watch(serviceProvider(id));
    return asyncService.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return ServiceSelectable(ref: ref, id: this, service: value);
    });
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceIdentifier && other.id == id;
  }

  @override
  String toString() => "ServiceIdentifier(id: $id)";
}

class ServiceSelectable extends Selectable<ServiceIdentifier> {
  ServiceSelectable({
    required this.ref,
    required this.id,
    required this.service,
  }) : _data = DynamicData(service.toJsonMap());

  @override
  final ServiceIdentifier id;

  final Service service;

  @override
  String get name => service.displayName;

  final Ref ref;

  final DynamicData _data;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
      },
    );
  }

  @override
  List<SelectableOperation> get operations => [
    if (service.isOnline)
      OpenSelectableOperation(
        onOpen: () async {
          final organizationId = ref.read(organizationIdProvider);
          if (organizationId == null) return;
          final router = ref.read(appRouterProvider);
          await router.navigate(
            OrganizationRoute(
              organizationId: organizationId,
              children: [RealmRoute(realmId: service.id)],
            ),
          );
        },
        allowMultiSelect: false,
      ),
    UnbindSelectableOperation(
      onUnbind: () =>
          ref.read(servicesProvider.notifier).deleteService(service.id),
    ),
  ];

  @override
  Widget? header() => ServiceHeader(
    id: service.id,
    name: service.displayName,
    color: service.color,
  );

  @override
  dynamic fieldValue(String path) {
    return _data.get(path);
  }

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final newService = Service()..mergeFromProto3Json(newData.toJson());
    ref.read(servicesProvider.notifier).updateService(newService);
  }

  @override
  int get hashCode => Object.hash(id, service);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ServiceSelectable) return false;
    return other.id == id && other.service == service;
  }

  @override
  String toString() => "ServiceSelectable(id: $id, service: $service)";
}
