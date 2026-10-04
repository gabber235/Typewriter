part of "services.dart";

/// Editor snapshot for one host's complete desired execution configuration.
///
/// The confirmed value is reconstructed from topology child membership, while
/// [topology] supplies available Realm and engine choices. Runtime observations
/// remain outside the draft and are never submitted as configuration.
final class HostEditorSnapshot extends EditorSnapshot {
  const HostEditorSnapshot(this.host, this.topology);
  final TopologyHost host;
  final OrganizationTopology topology;
  TopologyRealm? get _realm => topology.realmOwnedBy(host.hostId);
  TopologyEngine? get _engine => topology.engineOwnedBy(host.hostId);

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
    typeCatalog: _hostConfigurationCatalog,
    confirmedValue: _configurationValue(_realm, _engine),
    revision: host.revision,
  );
  @override
  List<TypeDiagnostic> validateDraft(DataValue value) {
    final shape = _configurationShapeIssues(value);
    return shape.isEmpty ? _configurationIssues(value) : shape;
  }

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    if (_admitsConfigurationValue(path, value)) {
      return EditorMutationResult.applied(value);
    }
    return EditorMutationResult.invalid([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "The host configuration value is invalid",
        path: path,
      ),
    ]);
  }

  bool _admitsConfigurationValue(DataPath path, DataValue value) {
    if (path == DataPath.root) return _configurationShapeIssues(value).isEmpty;
    if (path == DataPath.root.field("realm")) {
      return _isRealmConfiguration(value);
    }
    if (path == DataPath.root.field("engine")) {
      return _isEngineConfiguration(value);
    }
    if (path == DataPath.root.field("realm").field("target") ||
        path == DataPath.root.field("engine").field("target") ||
        path == DataPath.root.field("engine").field("realm")) {
      return value is StringValue;
    }
    return false;
  }

  List<TypeDiagnostic> _configurationShapeIssues(DataValue value) {
    if (value is RecordValue &&
        value.fields.length == 2 &&
        _isRealmConfiguration(value.fields["realm"]) &&
        _isEngineConfiguration(value.fields["engine"])) {
      return const [];
    }
    return const [
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "The host configuration structure is invalid",
      ),
    ];
  }

  bool _isRealmConfiguration(DataValue? value) => switch (value) {
    PolymorphicValue(:final concreteType, value: RecordValue(:final fields))
        when concreteType == _realmDisabled =>
      fields.isEmpty,
    PolymorphicValue(:final concreteType, value: RecordValue(:final fields))
        when concreteType == _realmHosted =>
      fields.length == 1 && fields["target"] is StringValue,
    _ => false,
  };

  bool _isEngineConfiguration(DataValue? value) => switch (value) {
    PolymorphicValue(:final concreteType, value: RecordValue(:final fields))
        when concreteType == _engineDisabled =>
      fields.isEmpty,
    PolymorphicValue(:final concreteType, value: RecordValue(:final fields))
        when concreteType == _engineEnabled =>
      fields.length == 2 &&
          fields["target"] is StringValue &&
          fields["realm"] is StringValue,
    _ => false,
  };
  TopologyEngineTarget? _decodeTarget(
    String? value,
    Map<String, List<String>> targets,
  ) {
    if (value == null) return null;
    final separator = value.lastIndexOf("@");
    if (separator <= 0) return null;
    final id = value.substring(0, separator);
    final constraint = value.substring(separator + 1);
    if (!(targets[id]?.contains(constraint) ?? false)) return null;

    return TopologyEngineTarget(engineId: id, versionConstraint: constraint);
  }
}

/// Bridges the host configuration editor to the organization resource session.
///
/// Refresh reads a topology snapshot. Commit preparation validates and decodes
/// the draft, then reserves the host and publishes accepted or conflicting
/// backend results through the repository topology stream.
final class HostEditorResource implements EditableResource {
  const HostEditorResource(this.repository, this.hostId);
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
  Future<EditorSnapshot?> refresh() async {
    final topology = await repository.topology();
    final host = topology.hosts.firstWhereOrNull(
      (value) => value.hostId == hostId,
    );
    return host == null ? null : HostEditorSnapshot(host, topology);
  }

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) {
    final current = snapshot as HostEditorSnapshot;
    final execution = current._decodeExecution(commit.rootValue);
    if (execution == null) {
      throw StateError("The host configuration is invalid");
    }
    return IndependentMutation(
      PendingCommit(
        resources: reservations,
        prepare: () => repository
            .configure(hostId, commit.expectedRevision, execution)
            .copyWith(
              integrate: (result) async {
                switch (result) {
                  case SubmissionConfirmed(:final value) ||
                      SubmissionRejected(
                        response: final skir.ConfigureServiceHostResponse value,
                      ):
                    switch (value) {
                      case skir.ConfigureServiceHostResponse_successWrapper(
                        :final value,
                      ):
                        repository.acceptConfiguration(value);
                        final actual = TopologyConfigurationResult.fromSkir(
                          value,
                        );
                        accept(
                          MutationSuccess(
                            revision: actual.host.revision,
                            value: current._configurationValue(
                              actual.realm,
                              actual.engine,
                            ),
                          ),
                        );
                      case skir.ConfigureServiceHostResponse_conflictErrorWrapper(
                        :final value,
                      ):
                        repository.acceptConfiguration(value.actual);
                        final actual = TopologyConfigurationResult.fromSkir(
                          value.actual,
                        );
                        accept(
                          MutationConflict(
                            expectedRevision: commit.expectedRevision,
                            actualRevision: actual.host.revision,
                            actualValue: current._configurationValue(
                              actual.realm,
                              actual.engine,
                            ),
                          ),
                        );
                      case skir.ConfigureServiceHostResponse_invalidConfigurationErrorWrapper(
                        :final value,
                      ):
                        accept(invalidMutation(value.message));
                      default:
                        accept(
                          unavailableMutation(
                            "The host configuration could not be applied",
                          ),
                        );
                    }
                  default:
                    break;
                }
              },
            ),
      ),
    );
  }
}
