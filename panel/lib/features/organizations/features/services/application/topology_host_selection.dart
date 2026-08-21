part of "services.dart";

/// Exposes a host and its backing service through the shared inspector editor.
///
/// Service identity and runtime observations are read only. Execution fields
/// are editable and commit as one optimistic topology configuration mutation.
/// The returned backend state becomes the editor value immediately, while the
/// topology watch remains the canonical source for later updates.
class _ServiceHostSelectable
    extends InspectableSelectable<ServiceHostIdentifier> {
  _ServiceHostSelectable({
    required this.ref,
    required this.id,
    required this.host,
    required this.service,
    required this.topology,
  });

  final Ref ref;
  @override
  final ServiceHostIdentifier id;
  final skir.ServiceHost host;
  final Service? service;
  final OrganizationTopology topology;

  skir.RealmInstance? get _realm => topology.realmOwnedBy(host.hostId);
  skir.EngineInstance? get _engine => topology.engineOwnedBy(host.hostId);

  Map<String, List<int>> get _realmTargets {
    final catalog = _engineTargetCatalog(
      topology.hosts.expand((candidate) => candidate.supportedEngines),
    );
    final target = _realm?.targetEngine;
    if (target != null) {
      catalog.putIfAbsent(target.engineId, () => []).add(target.majorVersion);
    }
    return catalog;
  }

  Map<String, List<int>> get _engineTargets {
    final catalog = _engineTargetCatalog(host.supportedEngines);
    final target = _engine?.target;
    if (target != null) {
      catalog.putIfAbsent(target.engineId, () => []).add(target.majorVersion);
    }
    return catalog;
  }

  @override
  String get name => service?.displayName ?? host.hostId.id;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(_hostInspectorTypeRef),
    typeCatalog: _hostInspectorCatalog,
    confirmedValue: _hostInspectorValue(host, _realm, _engine),
    revision: host.revision,
    presentations: [
      _hostInspectorPresentation(
        realmTargets: _realmTargets,
        engineTargets: _engineTargets,
        realms: topology.realmInstances,
      ),
    ],
  );

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() => ServiceHeader(
    id: host.hostId.id,
    name: name,
    color: service?.color ?? standaloneServiceColor,
  );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    const readOnlyFields = {
      _HostInspectorFields.serviceName,
      _HostInspectorFields.serviceId,
      _HostInspectorFields.serviceRoles,
      _HostInspectorFields.connected,
      _HostInspectorFields.entrypoint,
      _HostInspectorFields.runtimeStatus,
      _HostInspectorFields.runtimeMessage,
      _HostInspectorFields.topologyRevision,
      _HostInspectorFields.supportedEngines,
    };
    if (path.segments.firstOrNull case FieldPathSegment(
      :final name,
    ) when readOnlyFields.contains(name)) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "Host observation fields are read only",
          path: path,
        ),
      ]);
    }
    return super.validate(path, value);
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) async {
    final execution = _decodeExecution(commit.rootValue);
    if (execution == null) {
      return invalidMutation("The host execution configuration is invalid");
    }
    try {
      final configured = await ref
          .read(organizationTopologyStreamProvider.notifier)
          .configureHost(host: host, execution: execution);
      return TypedMutationResult.success(
        revision: configured.host.revision,
        value: _hostInspectorValue(
          configured.host,
          configured.realm,
          configured.engine,
        ),
      );
    } on ApiException catch (error) {
      return unavailableMutation(error.message);
    }
  }

  RecordValue _hostInspectorValue(
    skir.ServiceHost currentHost,
    skir.RealmInstance? realm,
    skir.EngineInstance? engine,
  ) {
    final realmTarget = realm?.targetEngine ?? _firstTarget(_realmTargets);
    final engineTarget = engine?.target ?? _firstTarget(_engineTargets);
    final localRealm = realm != null && engine?.realmId == realm.realmId;
    final serviceRole = service?.role;
    return RecordValue({
      _HostInspectorFields.serviceName: StringValue(
        service?.displayName ?? "Unavailable",
      ),
      _HostInspectorFields.serviceId: StringValue(currentHost.serviceId.id),
      _HostInspectorFields.serviceRoles: ListValue(
        serviceRole == null
            ? const []
            : [StringValue("${serviceRole.label} ${serviceRole.version}")],
      ),
      _HostInspectorFields.connected: BooleanValue(service?.isOnline ?? false),
      _HostInspectorFields.entrypoint: StringValue(
        currentHost.entrypoint.formatted,
      ),
      _HostInspectorFields.runtimeStatus: StringValue(
        _hostStatus(currentHost.state.status),
      ),
      _HostInspectorFields.runtimeMessage: StringValue(
        currentHost.state.message ?? "None",
      ),
      _HostInspectorFields.topologyRevision: StringValue(
        _revisionLabel(currentHost.topologyRevision),
      ),
      _HostInspectorFields.supportedEngines: ListValue(
        currentHost.supportedEngines
            .map(
              (supported) => StringValue(
                "${supported.engineId.formatted} ${supported.supportedMajorVersions.join(", ")}",
              ),
            )
            .toList(),
      ),
      _HostInspectorFields.realmEnabled: BooleanValue(realm != null),
      _HostInspectorFields.realmTarget: StringValue(
        realmTarget == null
            ? ""
            : _encodeTarget(realmTarget.engineId, realmTarget.majorVersion),
      ),
      _HostInspectorFields.engineEnabled: BooleanValue(engine != null),
      _HostInspectorFields.engineTarget: StringValue(
        engineTarget == null
            ? ""
            : _encodeTarget(engineTarget.engineId, engineTarget.majorVersion),
      ),
      _HostInspectorFields.realmAssignment: StringValue(
        localRealm ? "hosted" : engine?.realmId.id ?? realm?.realmId.id ?? "",
      ),
    });
  }

  skir.EngineTarget? _firstTarget(Map<String, List<int>> targets) {
    final id = targets.keys.firstOrNull;
    final major = id == null ? null : targets[id]?.firstOrNull;
    if (id == null || major == null) return null;
    return skir.EngineTarget(engineId: id, majorVersion: major);
  }

  skir.HostExecutionConfiguration? _decodeExecution(DataValue value) {
    if (value is! RecordValue) return null;
    final realmEnabled =
        value.fields[_HostInspectorFields.realmEnabled]?.booleanOrNull;
    final realmTarget = _decodeTarget(
      value.fields[_HostInspectorFields.realmTarget]?.stringOrNull,
      _realmTargets,
    );
    final engineEnabled =
        value.fields[_HostInspectorFields.engineEnabled]?.booleanOrNull;
    final engineTarget = _decodeTarget(
      value.fields[_HostInspectorFields.engineTarget]?.stringOrNull,
      _engineTargets,
    );
    final assignment =
        value.fields[_HostInspectorFields.realmAssignment]?.stringOrNull;
    if (realmEnabled == null || engineEnabled == null) return null;
    if (realmEnabled && realmTarget == null) {
      return null;
    }
    if (engineEnabled &&
        (engineTarget == null || assignment == null || assignment.isEmpty)) {
      return null;
    }
    final assignedRealm = topology.realmInstances.firstWhereOrNull(
      (realm) => realm.realmId.id == assignment,
    );
    if (engineEnabled && assignment != "hosted" && assignedRealm == null) {
      return null;
    }
    return skir.HostExecutionConfiguration(
      realm: realmEnabled
          ? skir.HostedRealmConfiguration(targetEngine: realmTarget!)
          : null,
      engine: engineEnabled
          ? skir.HostedEngineConfiguration(
              target: engineTarget!,
              realm: assignment == "hosted"
                  ? skir.EngineRealmSelection.hostedRealm
                  : skir.EngineRealmSelection.createExistingRealm(
                      realmId: assignedRealm!.realmId,
                    ),
            )
          : null,
    );
  }

  skir.EngineTarget? _decodeTarget(
    String? value,
    Map<String, List<int>> targets,
  ) {
    if (value == null) return null;
    final separator = value.lastIndexOf("@");
    if (separator <= 0) return null;
    final id = value.substring(0, separator);
    final major = int.tryParse(value.substring(separator + 1));
    if (major == null || !(targets[id]?.contains(major) ?? false)) return null;
    return skir.EngineTarget(engineId: id, majorVersion: major);
  }
}

extension on DataValue {
  bool? get booleanOrNull =>
      this is BooleanValue ? (this as BooleanValue).value : null;
  String? get stringOrNull =>
      this is StringValue ? (this as StringValue).value : null;
}
