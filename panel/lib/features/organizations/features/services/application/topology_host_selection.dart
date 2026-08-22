part of "services.dart";

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
    confirmedValue: _hostInspectorValue(host, service, _realm, _engine),
    revision: _combinedRevision(service, host),
    commitGroups: {
      DataPath.root.field(_HostInspectorFields.service): "service",
      DataPath.root.field(_HostInspectorFields.configuration): "configuration",
    },
    presentations: [
      _hostInspectorPresentation(
        realmTargets: _realmTargets,
        engineTargets: _engineTargets,
        realms: topology.realmInstances,
        canHostRealm: host.canHostRealm,
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
    final serviceNamePath = _hostPath(
      _HostInspectorFields.service,
      _HostInspectorFields.name,
    );
    final configurationPath = DataPath.root.field(
      _HostInspectorFields.configuration,
    );
    if (path.isAtOrBelow(serviceNamePath) ||
        path.isAtOrBelow(configurationPath)) {
      return super.validate(path, value);
    }
    return EditorMutationResult.invalid([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPath,
        message: "Service and host observation fields are read only",
        path: path,
      ),
    ]);
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) =>
      switch (commit.group) {
        "service" => _commitService(commit),
        "configuration" => _commitConfiguration(commit),
        _ => Future.value(
          invalidMutation("The selected host field is read only"),
        ),
      };

  Future<TypedMutationResult> _commitService(EditorCommit commit) async {
    final currentService = service;
    final value = commit.rootValue;
    if (currentService == null || value is! RecordValue) {
      return unavailableMutation("The host service is unavailable");
    }
    final serviceValue = value.fields[_HostInspectorFields.service];
    final nextName = serviceValue is RecordValue
        ? serviceValue.fields[_HostInspectorFields.name]?.stringOrNull
        : null;
    if (nextName == null || nextName.trim().isEmpty) {
      return invalidMutation("The service name must not be empty");
    }
    final result = await ref
        .read(servicesProvider.notifier)
        .updateService(
          currentService.copyWith(
            revision: currentService.revision,
            name: nextName,
          ),
        );
    final canonical = ref
        .read(servicesProvider)
        .value
        ?.firstWhereOrNull(
          (candidate) => candidate.serviceId == currentService.serviceId,
        );
    return switch (result) {
      MutationSuccess() when canonical != null => TypedMutationResult.success(
        revision: _combinedRevision(canonical, host),
        value: _hostInspectorValue(host, canonical, _realm, _engine),
      ),
      MutationConflict(:final expectedRevision) when canonical != null =>
        TypedMutationResult.conflict(
          expectedRevision: expectedRevision,
          actualRevision: _combinedRevision(canonical, host),
          actualValue: _hostInspectorValue(host, canonical, _realm, _engine),
        ),
      _ => result,
    };
  }

  Future<TypedMutationResult> _commitConfiguration(EditorCommit commit) async {
    final execution = _decodeExecution(commit.rootValue);
    if (execution == null) {
      return invalidMutation("The host configuration is invalid");
    }
    try {
      final configured = await ref
          .read(organizationTopologyStreamProvider.notifier)
          .configureHost(host: host, execution: execution);
      return TypedMutationResult.success(
        revision: _combinedRevision(service, configured.host),
        value: _hostInspectorValue(
          configured.host,
          service,
          configured.realm,
          configured.engine,
        ),
      );
    } on _HostConfigurationConflict catch (conflict) {
      return TypedMutationResult.conflict(
        expectedRevision: commit.expectedRevision,
        actualRevision: _combinedRevision(service, conflict.actual),
        actualValue: _hostInspectorValue(
          conflict.actual,
          service,
          _realm,
          _engine,
        ),
      );
    } on ApiException catch (error) {
      return unavailableMutation(error.message);
    }
  }

  int _combinedRevision(
    Service? currentService,
    skir.ServiceHost currentHost,
  ) => (currentService?.revision ?? 0) + currentHost.revision;

  RecordValue _hostInspectorValue(
    skir.ServiceHost currentHost,
    Service? currentService,
    skir.RealmInstance? realm,
    skir.EngineInstance? engine,
  ) {
    final realmTarget = realm?.targetEngine ?? _firstTarget(_realmTargets);
    final engineTarget = engine?.target ?? _firstTarget(_engineTargets);
    final localRealm = realm != null && engine?.realm.realmId == realm.realmId;
    return RecordValue({
      _HostInspectorFields.service: RecordValue({
        _HostInspectorFields.name: StringValue(
          currentService?.name ?? "Unavailable",
        ),
        _HostInspectorFields.version: StringValue(
          currentService?.role.version ?? "Unavailable",
        ),
        _HostInspectorFields.state: StringValue(
          currentService?.isOnline ?? false ? "Connected" : "Offline",
        ),
        _HostInspectorFields.lastSeen: StringValue(
          currentService?.lastSeenLabel ?? "Never",
        ),
      }),
      _HostInspectorFields.host: RecordValue({
        _HostInspectorFields.entrypoint: StringValue(
          currentHost.entrypoint.formatted,
        ),
        _HostInspectorFields.canHostRealm: BooleanValue(
          currentHost.canHostRealm,
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
        _HostInspectorFields.state: StringValue(
          hostRuntimeStatusLabel(currentHost.state.status),
        ),
        _HostInspectorFields.message: StringValue(
          currentHost.state.message ?? "None",
        ),
        _HostInspectorFields.updatedAt: StringValue(
          currentHost.state.updatedAt.toLocal().toIso8601String(),
        ),
      }),
      _HostInspectorFields.configuration: RecordValue({
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
          localRealm
              ? "hosted"
              : engine?.realm.realmId.id ?? realm?.realmId.id ?? "",
        ),
      }),
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
    final configuration = value.fields[_HostInspectorFields.configuration];
    if (configuration is! RecordValue) return null;
    final realmEnabled =
        configuration.fields[_HostInspectorFields.realmEnabled]?.booleanOrNull;
    final realmTarget = _decodeTarget(
      configuration.fields[_HostInspectorFields.realmTarget]?.stringOrNull,
      _realmTargets,
    );
    final engineEnabled =
        configuration.fields[_HostInspectorFields.engineEnabled]?.booleanOrNull;
    final engineTarget = _decodeTarget(
      configuration.fields[_HostInspectorFields.engineTarget]?.stringOrNull,
      _engineTargets,
    );
    final assignment = configuration
        .fields[_HostInspectorFields.realmAssignment]
        ?.stringOrNull;
    if (realmEnabled == null || engineEnabled == null) return null;
    if (realmEnabled && (!host.canHostRealm || realmTarget == null)) {
      return null;
    }
    if (engineEnabled &&
        (engineTarget == null || assignment == null || assignment.isEmpty)) {
      return null;
    }
    if (engineEnabled && assignment == "hosted" && !realmEnabled) return null;
    final assignedRealm = topology.realmInstances.firstWhereOrNull(
      (candidate) => candidate.realmId.id == assignment,
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
