part of "services.dart";

const engineServiceRoleColor = Colors.blueAccent;
const realmServiceRoleColor = Colors.deepOrangeAccent;
const customServiceRoleColor = Colors.green;
const standaloneServiceColor = Colors.blueGrey;

@freezed
abstract class Service with _$Service {
  @Assert("name.isNotEmpty", "Name must not be empty.")
  @Assert("roles.isNotEmpty", "Roles must not be empty.")
  factory Service({
    required skir.RecordId serviceId,
    required int revision,
    required String name,
    required List<ServiceRole> roles,
    required DateTime createdAt,
    skir.RecordId? organization,
    ServiceRegistration? registration,
    ServiceState? state,
    skir.RecordId? runsIn,
  }) = _Service;

  const Service._();

  factory Service.fromSkir(skir.Service service) => Service(
    serviceId: service.serviceId,
    revision: service.revision,
    name: service.name,
    roles: service.roles.map(ServiceRole.fromSkir).toList(),
    createdAt: service.createdAt,
    organization: service.organization,
    registration: service.registration != null
        ? ServiceRegistration.fromSkir(service.registration!)
        : null,
    state: service.state != null ? ServiceState.fromSkir(service.state!) : null,
    runsIn: service.runsIn,
  );

  skir.Service toSkir() => skir.Service(
    serviceId: serviceId,
    revision: revision,
    name: name,
    roles: roles.map((role) => role.toSkir()).toList(),
    createdAt: createdAt,
    organization: organization,
    registration: registration?.toSkir(),
    state: state?.toSkir(),
    runsIn: runsIn,
  );

  String get displayName =>
      name.isNotEmpty ? name.formatted : "Unnamed Service";

  Color get color => roles.map((role) => role.color).toList().mix();

  bool get isOnline => state?.isOnline ?? false;

  DateTime? get lastSeen => state?.lastSeen;
  String get lastSeenLabel => state?.lastSeenLabel ?? "Never";

  String get label => roles.map((role) => role.label).toList().join(" & ");

  DateTime get nextTimeout => state?.nextTimeout ?? lastSeen ?? DateTime.now();

  bool get isEngine => roles.any((role) => role is EngineServiceRole);
  bool get isRealm => roles.any((role) => role is RealmServiceRole);
  bool get isCustom => roles.any((role) => role is CustomServiceRole);

  IconData get icon {
    return switch ((isEngine, isRealm, isCustom)) {
      (true, true, _) || (true, _, true) || (_, true, true) => Icons.dns,
      (true, false, false) => Icons.memory,
      (false, true, false) => Icons.cloud,
      (false, false, true) => Icons.extension,
      (false, false, false) => throw UnimplementedError(),
    };
  }
}

@freezed
sealed class ServiceRole with _$ServiceRole {
  @Assert("version.isNotEmpty", "Version must not be empty.")
  factory ServiceRole.engine({required String version}) = EngineServiceRole;
  @Assert("version.isNotEmpty", "Version must not be empty.")
  factory ServiceRole.realm({required String version}) = RealmServiceRole;

  @Assert("version.isNotEmpty", "Version must not be empty.")
  @Assert("name.isNotEmpty", "Name must not be empty.")
  factory ServiceRole.custom({required String version, required String name}) =
      CustomServiceRole;

  const ServiceRole._();

  factory ServiceRole.fromSkir(skir.ServiceRole role) {
    return switch (role) {
      skir.ServiceRole_engineWrapper(value: final engine) => ServiceRole.engine(
        version: engine.version,
      ),
      skir.ServiceRole_realmWrapper(value: final realm) => ServiceRole.realm(
        version: realm.version,
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
      EngineServiceRole(version: final version) =>
        skir.ServiceRole.createEngine(version: version),
      RealmServiceRole(version: final version) => skir.ServiceRole.createRealm(
        version: version,
      ),
      CustomServiceRole(version: final version, name: final name) =>
        skir.ServiceRole.createCustom(version: version, name: name),
    };
  }

  Color get color => switch (this) {
    EngineServiceRole() => engineServiceRoleColor,
    RealmServiceRole() => realmServiceRoleColor,
    CustomServiceRole() => customServiceRoleColor,
  };

  String get label => switch (this) {
    EngineServiceRole() => "Engine",
    RealmServiceRole() => "Realm",
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
