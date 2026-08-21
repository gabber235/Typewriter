part of "services.dart";

const engineServiceRoleColor = Colors.blueAccent;
const realmServiceRoleColor = Colors.deepOrangeAccent;
const customServiceRoleColor = Colors.green;
const standaloneServiceColor = Colors.blueGrey;

@freezed
abstract class Service with _$Service {
  @Assert("name.isNotEmpty", "Name must not be empty.")
  factory Service({
    required skir.RecordId serviceId,
    required int revision,
    required String name,
    required ServiceRole role,
    required DateTime createdAt,
    skir.RecordId? organization,
    ServiceRegistration? registration,
    ServiceState? state,
  }) = _Service;

  const Service._();

  factory Service.fromSkir(skir.Service service) => Service(
    serviceId: service.serviceId,
    revision: service.revision,
    name: service.name,
    role: ServiceRole.fromSkir(service.role),
    createdAt: service.createdAt,
    organization: service.organization,
    registration: service.registration != null
        ? ServiceRegistration.fromSkir(service.registration!)
        : null,
    state: service.state != null ? ServiceState.fromSkir(service.state!) : null,
  );

  skir.Service toSkir() => skir.Service(
    serviceId: serviceId,
    revision: revision,
    name: name,
    role: role.toSkir(),
    createdAt: createdAt,
    organization: organization,
    registration: registration?.toSkir(),
    state: state?.toSkir(),
  );

  String get displayName =>
      name.isNotEmpty ? name.formatted : "Unnamed Service";

  Color get color => role.color;

  bool get isOnline => state?.isOnline ?? false;

  DateTime? get lastSeen => state?.lastSeen;
  String get lastSeenLabel => state?.lastSeenLabel ?? "Never";

  String get label => role.label;

  DateTime get nextTimeout => state?.nextTimeout ?? lastSeen ?? DateTime.now();

  bool get isHost => role is HostServiceRole;
  bool get isCustom => role is CustomServiceRole;
  bool get isRealm => switch (role) {
    CustomServiceRole(name: "realm") => true,
    _ => false,
  };

  IconData get icon {
    return switch (role) {
      HostServiceRole() => Icons.dns,
      CustomServiceRole() => Icons.extension,
    };
  }
}

@freezed
sealed class ServiceRole with _$ServiceRole {
  @Assert("version.isNotEmpty", "Version must not be empty.")
  factory ServiceRole.host({required String version}) = HostServiceRole;

  @Assert("version.isNotEmpty", "Version must not be empty.")
  @Assert("name.isNotEmpty", "Name must not be empty.")
  factory ServiceRole.custom({required String version, required String name}) =
      CustomServiceRole;

  const ServiceRole._();

  factory ServiceRole.fromSkir(skir.ServiceRole role) {
    return switch (role) {
      skir.ServiceRole_hostWrapper(value: final host) => ServiceRole.host(
        version: host.version,
      ),
      skir.ServiceRole_customWrapper(value: final custom) => ServiceRole.custom(
        version: custom.version,
        name: custom.name,
      ),
      skir.ServiceRole_unknown() => throw ApiException.unknown("service role"),
    };
  }

  skir.ServiceRole toSkir() {
    return switch (this) {
      HostServiceRole(version: final version) => skir.ServiceRole.createHost(
        version: version,
      ),
      CustomServiceRole(version: final version, name: final name) =>
        skir.ServiceRole.createCustom(version: version, name: name),
    };
  }

  Color get color => switch (this) {
    HostServiceRole() => standaloneServiceColor,
    CustomServiceRole() => customServiceRoleColor,
  };

  String get label => switch (this) {
    HostServiceRole() => "Host",
    CustomServiceRole(:final name) => name,
  };
}

@freezed
abstract class ServiceRegistration with _$ServiceRegistration {
  const factory ServiceRegistration({
    required String token,
    required DateTime expiresAt,
  }) = _ServiceRegistration;

  const ServiceRegistration._();

  factory ServiceRegistration.fromSkir(skir.ServiceRegistration registration) {
    return ServiceRegistration(
      token: registration.token,
      expiresAt: registration.expiresAt,
    );
  }

  skir.ServiceRegistration toSkir() {
    return skir.ServiceRegistration(token: token, expiresAt: expiresAt);
  }
}

const _serviceStateTimeout = Duration(minutes: 2);

@freezed
abstract class ServiceState with _$ServiceState {
  const factory ServiceState({
    required ServiceStateStatus status,
    required DateTime lastSeen,
  }) = _ServiceState;

  const ServiceState._();

  factory ServiceState.fromSkir(skir.ServiceState state) {
    return ServiceState(
      status: ServiceStateStatus.fromSkir(state.status),
      lastSeen: state.lastSeen,
    );
  }

  skir.ServiceState toSkir() {
    return skir.ServiceState(status: status.toSkir(), lastSeen: lastSeen);
  }

  bool get isOnline {
    if (status == ServiceStateStatus.offline) return false;
    return DateTime.now().difference(lastSeen) < _serviceStateTimeout;
  }

  DateTime get nextTimeout {
    if (status == ServiceStateStatus.offline) return lastSeen;
    return lastSeen.add(_serviceStateTimeout);
  }

  String get lastSeenLabel {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inSeconds < 60) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return "${difference.inDays}d ago";
  }
}

enum ServiceStateStatus {
  online,
  offline;

  factory ServiceStateStatus.fromSkir(skir.ServiceStatus status) {
    return switch (status) {
      skir.ServiceStatus.online => ServiceStateStatus.online,
      skir.ServiceStatus.offline => ServiceStateStatus.offline,
      skir.ServiceStatus_unknown() => throw ApiException.unknown(
        "service status",
      ),
    };
  }

  skir.ServiceStatus toSkir() {
    return switch (this) {
      ServiceStateStatus.online => skir.ServiceStatus.online,
      ServiceStateStatus.offline => skir.ServiceStatus.offline,
    };
  }
}

({List<Service> values, Service canonical}) _upsertCanonicalService(
  List<Service>? values,
  Service incoming,
) => reconcileCanonicalRevision(
  values: values,
  incoming: incoming,
  keyOf: (service) => service.serviceId,
  revisionOf: (service) => service.revision,
  identityOf: (service) => "Service ${service.serviceId.id}",
  entityName: "Service",
);
