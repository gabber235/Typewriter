part of "services.dart";

/// Editor snapshot for one host's complete desired execution configuration.
///
/// The confirmed value is reconstructed from topology child membership, while
/// [topology] supplies available Realm and engine choices. Runtime observations
/// remain outside the draft and are never submitted as configuration.
final class HostEditorSnapshot extends EditorSnapshot {
  const HostEditorSnapshot(this.host, this.topology);
  final skir.ServiceHost host;
  final skir.OrganizationTopologySnapshot topology;
  skir.RealmInstance? get _realm => topology.realmOwnedBy(host.hostId);
  skir.EngineInstance? get _engine => topology.engineOwnedBy(host.hostId);

  Map<String, List<String>> get _realmTargets {
    final catalog = _engineTargetCatalog(
      topology.hosts.expand((candidate) => candidate.supportedEngines),
    );
    final target = _realm?.targetEngine;
    if (target != null) {
      final constraints = catalog.putIfAbsent(target.engineId, () => []);
      if (!constraints.contains(target.versionConstraint)) {
        constraints.add(target.versionConstraint);
      }
    }
    return catalog;
  }

  Map<String, List<String>> get _engineTargets {
    final catalog = _engineTargetCatalog(host.supportedEngines);
    final target = _engine?.target;
    if (target != null) {
      final constraints = catalog.putIfAbsent(target.engineId, () => []);
      if (!constraints.contains(target.versionConstraint)) {
        constraints.add(target.versionConstraint);
      }
    }
    return catalog;
  }

  @override
  EditorDocument get document => EditorDocument(
    rootType: _hostConfigurationType,
    catalog: _hostConfigurationCatalog,
    confirmedValue: _configurationValue(_realm, _engine),
    revision: host.revision,
  );
  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) {
    final shape = _configurationShapeIssues(value);
    return shape.isEmpty ? _configurationIssues(value) : shape;
  }

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) {
    if (_admitsConfigurationValue(path, value)) {
      return EditorMutationResult.applied(value);
    }
    return EditorMutationResult.invalid([
      EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "The host configuration value is invalid",
        path: path,
      ),
    ]);
  }

  bool _admitsConfigurationValue(skir.ValuePath path, skir.DataValue value) {
    if (path == editorRootPath) return _configurationShapeIssues(value).isEmpty;
    if (path == editorRootPath.field("realm")) {
      return _isRealmConfiguration(value);
    }
    if (path == editorRootPath.field("engine")) {
      return _isEngineConfiguration(value);
    }
    if (path == editorRootPath.field("realm").field("target") ||
        path == editorRootPath.field("engine").field("target") ||
        path == editorRootPath.field("engine").field("realm")) {
      return value is skir.DataValue_stringValueWrapper;
    }
    return false;
  }

  List<EditorDiagnostic> _configurationShapeIssues(skir.DataValue value) {
    final fields = value.authoredRecord?.fields.toList(growable: false);
    if (fields != null &&
        fields.length == 2 &&
        _isRealmConfiguration(
          value.editorValueAt(editorRootPath.field("realm")),
        ) &&
        _isEngineConfiguration(
          value.editorValueAt(editorRootPath.field("engine")),
        )) {
      return const [];
    }
    return const [
      EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "The host configuration structure is invalid",
      ),
    ];
  }

  bool _isRealmConfiguration(skir.DataValue? value) {
    if (value == null) return false;
    if (_actualType(value) == _realmDisabled) {
      return value.authoredRecord?.fields.isEmpty ?? false;
    }
    return _actualType(value) == _realmHosted &&
        value.authoredRecord?.fields.length == 1 &&
        value.editorValueAt(editorRootPath.field("target"))
            is skir.DataValue_stringValueWrapper;
  }

  bool _isEngineConfiguration(skir.DataValue? value) {
    if (value == null) return false;
    if (_actualType(value) == _engineDisabled) {
      return value.authoredRecord?.fields.isEmpty ?? false;
    }
    return _actualType(value) == _engineEnabled &&
        value.authoredRecord?.fields.length == 2 &&
        value.editorValueAt(editorRootPath.field("target"))
            is skir.DataValue_stringValueWrapper &&
        value.editorValueAt(editorRootPath.field("realm"))
            is skir.DataValue_stringValueWrapper;
  }

  skir.EngineTarget? _decodeTarget(
    String? value,
    Map<String, List<String>> targets,
  ) {
    if (value == null) return null;
    final separator = value.lastIndexOf("@");
    if (separator <= 0) return null;
    final id = value.substring(0, separator);
    final constraint = value.substring(separator + 1);
    if (!(targets[id]?.contains(constraint) ?? false)) return null;

    return skir.EngineTarget(engineId: id, versionConstraint: constraint);
  }
}

/// Bridges the host configuration editor to the organization resource session.
///
/// Refresh reads a topology snapshot. Commit preparation validates and decodes
/// the draft and declares its host reservation. When that prepared command is
/// submitted, accepted and conflicting results enter the repository topology
/// stream before being mapped to editor outcomes.
final class HostEditPersistence extends ValueEditPersistence {
  const HostEditPersistence(this.repository, this.hostId);
  final ServiceResourceRepository repository;
  final skir.RecordId hostId;
  @override
  EditorResourceKey get key => EditorResourceKey(
    scope: EditorResourceScope(organizationId: repository.organization),
    identity: hostId,
  );
  @override
  Set<Object> get reservations => {(repository.organization, hostId)};
  @override
  Future<EditorSnapshot?> refreshSnapshot() async {
    final topology = await repository.topology();
    final host = topology.hosts.firstWhereOrNull(
      (value) => value.hostId == hostId,
    );
    return host == null ? null : HostEditorSnapshot(host, topology);
  }

  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final current = snapshot is HostEditorSnapshot
        ? snapshot
        : (snapshot as ResultEditorSnapshot).delegate as HostEditorSnapshot;
    final execution = current._decodeExecution(commit.rootValue);
    if (execution == null) {
      throw StateError("The host configuration is invalid");
    }
    TypedMutationResult observed(
      skir.HostConfigurationChange actual, {
      required bool conflict,
    }) {
      final value = current._configurationValue(actual.realm, actual.engine);
      return conflict
          ? MutationConflict(
              expectedRevision: commit.expectedRevision,
              actualRevision: actual.host.revision,
              actualValue: value,
            )
          : MutationSuccess(revision: actual.host.revision, value: value);
    }

    return repository
        .configure(hostId, commit.expectedRevision, execution)
        .mapResponse(
          (response) => switch (response) {
            skir.ConfigureServiceHostResponse_successWrapper(:final value) =>
              observed(value, conflict: false),
            skir.ConfigureServiceHostResponse_conflictErrorWrapper(
              :final value,
            ) =>
              observed(value.actual, conflict: true),
            skir.ConfigureServiceHostResponse_invalidConfigurationErrorWrapper(
              :final value,
            ) =>
              invalidMutation(value.message),
            _ => unavailableMutation(
              "The host configuration could not be applied",
            ),
          },
        );
  }
}
