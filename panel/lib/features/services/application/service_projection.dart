part of "services.dart";

const engineServiceRoleColor = Colors.blueAccent;
const realmServiceRoleColor = Colors.deepOrangeAccent;
const customServiceRoleColor = Colors.green;
const standaloneServiceColor = Colors.blueGrey;

/// Admits service identities whose role and connection status this panel
/// understands.
///
/// Unknown roles or statuses come from a newer contract. They are rejected
/// where values enter the canonical service projection, so presentation code
/// never has to invent a meaning for them.
extension ServiceAdmission on skir.Service {
  skir.Service requireKnown() {
    if (role is skir.ServiceRole_unknown) _unknownServiceRole();
    if (state?.status is skir.ServiceStatus_unknown) {
      throw ApiException.unknown("service status");
    }
    return this;
  }
}

Never _unknownServiceRole() => throw ApiException.unknown("service role");

/// Presentation of the organization identity of a service and its reported
/// connection state.
///
/// A [skir.Service] identifies the logical service record. A host runtime
/// resource in [skir.OrganizationTopologySnapshot] is a separate operational
/// record linked through its service identifier. Use these facts for naming
/// and service connection, not for inferring which realm or engine instances
/// are running.
extension ServicePresentation on skir.Service {
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
  bool get isHost => role is skir.ServiceRole_hostWrapper;

  /// Whether this identity represents a custom service.
  bool get isCustom => role is skir.ServiceRole_customWrapper;

  /// Whether this custom service has the reserved realm role.
  bool get isRealm => switch (role) {
    skir.ServiceRole_customWrapper(:final value) => value.name == "realm",
    _ => false,
  };

  /// The icon used for this service role in the panel.
  IconData get icon => switch (role) {
    skir.ServiceRole_hostWrapper() => Icons.dns,
    skir.ServiceRole_customWrapper() => Icons.extension,
    skir.ServiceRole_unknown() => _unknownServiceRole(),
  };
}

/// Converts the editable portion of a service into the local editor model.
///
/// The editor projects local identity values over canonical service data. It
/// does not replace the canonical revision or runtime state, and consumers
/// should use the canonical service for mutation expectations.
extension ServiceIdentityConversion on skir.Service {
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
  skir.Service? withIdentityValue(skir.DataValue value) {
    final name = value
        .editorValueAt(editorRootPath.field("name"))
        ?.authoredString;
    if (name == null || name.trim().isEmpty) return null;
    return (toMutable()..name = name).toFrozen();
  }

  /// Projects unsaved identity edits over canonical data for presentation.
  ///
  /// A failed projection leaves the canonical service unchanged.
  skir.Service projected(LocalEditorValue? local) {
    if (local == null) return this;
    return withIdentityValue(local.projectOnto(identityValue)) ?? this;
  }
}

/// Presents the runtime role a service identity provides.
extension ServiceRolePresentation on skir.ServiceRole {
  Color get color => switch (this) {
    skir.ServiceRole_hostWrapper() => standaloneServiceColor,
    skir.ServiceRole_customWrapper() => customServiceRoleColor,
    skir.ServiceRole_unknown() => _unknownServiceRole(),
  };

  String get version => switch (this) {
    skir.ServiceRole_hostWrapper(:final value) => value.version,
    skir.ServiceRole_customWrapper(:final value) => value.version,
    skir.ServiceRole_unknown() => _unknownServiceRole(),
  };

  String get label => switch (this) {
    skir.ServiceRole_hostWrapper() => "Host",
    skir.ServiceRole_customWrapper(:final value) => value.name,
    skir.ServiceRole_unknown() => _unknownServiceRole(),
  };
}

const _serviceStateTimeout = Duration(minutes: 2);

/// Freshness of the connection information reported by a service identity.
///
/// Freshness uses the service heartbeat policy rather than the host runtime
/// status in the topology model.
extension ServiceStateFreshness on skir.ServiceState {
  /// Returns whether this state is connected and within its freshness window.
  bool isConnectedAt(DateTime now) =>
      status == skir.ServiceStatus.online &&
      now.difference(lastSeen) < _serviceStateTimeout;

  DateTime get nextTimeout {
    if (status == skir.ServiceStatus.offline) return lastSeen;
    return lastSeen.add(_serviceStateTimeout);
  }
}

extension ServiceCollectionReconciliation on List<skir.Service>? {
  CanonicalReconciliation<skir.Service> reconcileCanonical(
    skir.Service incoming,
  ) => reconcileRevision(
    incoming: incoming,
    keyOf: (service) => service.serviceId,
    revisionOf: (service) => service.revision,
    identityOf: (service) => "Service ${service.serviceId.id}",
    entityName: "Service",
  );

  /// Accepts heartbeat changes at an unchanged identity revision.
  ///
  /// Every other field must match for this exception to strict canonical
  /// reconciliation. Watch updates use arrival order for heartbeat state;
  /// snapshot reconciliation separately retains the newest timestamp.
  CanonicalReconciliation<skir.Service> reconcileWatched(
    skir.Service incoming,
  ) {
    final values = this;
    final current = values?.firstWhereOrNull(
      (service) => service.serviceId == incoming.serviceId,
    );
    if (current?.revision == incoming.revision &&
        current?.withState(incoming.state) == incoming) {
      return CanonicalReconciliation(
        values: [
          for (final service in values!)
            if (service.serviceId == incoming.serviceId) incoming else service,
        ],
        canonical: incoming,
      );
    }
    return reconcileCanonical(incoming);
  }
}

extension ServiceStateReplacement on skir.Service {
  /// Returns this identity carrying [state] as its connection observation.
  skir.Service withState(skir.ServiceState? state) =>
      (toMutable()..state = state).toFrozen();
}
