part of "services.dart";

const engineServiceRoleColor = Colors.blueAccent;
const realmServiceRoleColor = Colors.deepOrangeAccent;
const customServiceRoleColor = Colors.green;
const standaloneServiceColor = Colors.blueGrey;

/// The organization identity of a service and its reported connection state.
///
/// A [Service] identifies the logical service record. A host runtime resource
/// in [OrganizationTopology] is a separate operational record linked through
/// its service identifier. Use this model for naming and service connection
/// facts, not for inferring which realm or engine instances are running.
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

  /// A presentation name derived from the editable service identity.
  String get displayName =>
      name.isNotEmpty ? name.formatted : "Unnamed Service";

  /// The UI color associated with the service role.
  Color get color => role.color;

  /// Whether the reported service state is still fresh at [now].
  bool isConnectedAt(DateTime now) => state?.isConnectedAt(now) ?? false;

  /// The last heartbeat reported by the service, when available.
  DateTime? get lastSeen => state?.lastSeen;

  /// A short role label for service presentations.
  String get label => role.label;

  /// The time at which a connected service stops being considered fresh.
  DateTime? get connectionDeadline => state?.nextTimeout;

  /// Whether this identity represents a host service.
  bool get isHost => role is HostServiceRole;

  /// Whether this identity represents a custom service.
  bool get isCustom => role is CustomServiceRole;

  /// Whether this custom service has the reserved realm role.
  bool get isRealm => switch (role) {
    CustomServiceRole(name: "realm") => true,
    _ => false,
  };

  /// The icon used for this service role in the panel.
  IconData get icon {
    return switch (role) {
      HostServiceRole() => Icons.dns,
      CustomServiceRole() => Icons.extension,
    };
  }
}

/// Converts the editable portion of a service into the local editor model.
///
/// The editor projects local identity values over canonical service data. It
/// does not replace the canonical revision or runtime state, and consumers
/// should use the canonical service for mutation expectations.
extension ServiceIdentityConversion on Service {
  /// The canonical value owned by the service identity editor.
  skir.DataValue get identityValue => skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
    ],
  );

  /// Returns this identity with [value] applied when it is valid.
  Service? withIdentityValue(skir.DataValue value) {
    final name = value
        .editorValueAt(editorRootPath.field("name"))
        ?.authoredString;
    if (name == null || name.trim().isEmpty) return null;
    return copyWith(name: name);
  }

  /// Projects unsaved identity edits over canonical data for presentation.
  ///
  /// A failed projection leaves the canonical service unchanged.
  Service projected(LocalEditorValue? local) {
    if (local == null) return this;
    return withIdentityValue(local.projectOnto(identityValue)) ?? this;
  }
}

/// Classifies the service identity by the runtime role it provides.
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

/// Temporary credentials and expiry data used to register a service.
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

/// Connection information reported by a logical service identity.
///
/// Freshness is evaluated by [isConnectedAt], using the service heartbeat
/// policy rather than the host runtime status in the topology model.
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

  /// Returns whether this state is connected and within its freshness window.
  bool isConnectedAt(DateTime now) {
    if (status == ServiceStateStatus.offline) return false;
    return now.difference(lastSeen) < _serviceStateTimeout;
  }

  DateTime get nextTimeout {
    if (status == ServiceStateStatus.offline) return lastSeen;
    return lastSeen.add(_serviceStateTimeout);
  }
}

/// Connection status reported by a service identity.
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

({List<Service> values, Service canonical}) _upsertWatchedService(
  List<Service>? values,
  Service incoming,
) {
  final current = values?.firstWhereOrNull(
    (service) => service.serviceId == incoming.serviceId,
  );
  if (current?.revision == incoming.revision &&
      current?.copyWith(state: incoming.state) == incoming) {
    return (
      values: [
        for (final service in values!)
          if (service.serviceId == incoming.serviceId) incoming else service,
      ],
      canonical: incoming,
    );
  }
  return _upsertCanonicalService(values, incoming);
}
