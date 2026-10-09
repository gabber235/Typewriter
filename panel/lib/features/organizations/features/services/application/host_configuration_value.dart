part of "services.dart";

extension _HostConfigurationValue on HostEditorSnapshot {
  skir.DataValue _configurationValue(
    TopologyRealm? realm,
    TopologyEngine? engine,
  ) => skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "realm",
        value: realm == null
            ? _draftVariant(_realmDisabled)
            : _draftVariant(_realmHosted, {
                "target": skir.DataValue.wrapStringValue(
                  _encodeTarget(
                    realm.targetEngine.engineId,
                    realm.targetEngine.versionConstraint,
                  ),
                ),
              }),
      ),
      skir.FieldValue(
        name: "engine",
        value: engine == null
            ? _draftVariant(_engineDisabled)
            : _draftVariant(_engineEnabled, {
                "target": skir.DataValue.wrapStringValue(
                  _encodeTarget(
                    engine.target.engineId,
                    engine.target.versionConstraint,
                  ),
                ),
                "realm": skir.DataValue.wrapStringValue(
                  realm?.realmId == engine.realm.realmId &&
                          realm?.targetEngine == engine.target
                      ? ""
                      : engine.realm.realmId.id,
                ),
              }),
      ),
    ],
  );

  List<EditorDiagnostic> _configurationIssues(skir.DataValue value) {
    final issues = <EditorDiagnostic>[];
    void issue(String path, String message) {
      var location = editorRootPath;
      for (final field in path.split(".")) {
        location = location.field(field);
      }
      issues.add(
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: message,
          path: location,
        ),
      );
    }

    final realm = value.editorValueAt(editorRootPath.field("realm"));
    final engine = value.editorValueAt(editorRootPath.field("engine"));
    if (realm == null || engine == null) {
      issue("realm", "Choose a workload configuration");
      return issues;
    }
    if (_actualType(realm) == _realmHosted) {
      if (!host.canHostRealm) issue("realm", "This host cannot run a Realm");
      if (_decodeTarget(_draftString(realm, "target"), _realmTargets) == null) {
        issue("realm.target", "Choose a supported Realm target");
      }
    }
    if (_actualType(engine) != _engineEnabled) return issues;
    if (_decodeTarget(_draftString(engine, "target"), _engineTargets) == null) {
      issue("engine.target", "Choose a supported engine target");
    }
    if (!_usesHostedRealm(realm, engine) &&
        !topology.realmInstances.any(
          (candidate) =>
              candidate.realmId.id == _draftString(engine, "realm") &&
              candidate.ownerHost.id != host.hostId &&
              _encodeTarget(
                    candidate.targetEngine.engineId,
                    candidate.targetEngine.versionConstraint,
                  ) ==
                  _draftString(engine, "target"),
        )) {
      issue("engine.realm", "Choose an available Realm");
    }
    return issues;
  }

  skir.HostExecutionConfiguration? _decodeExecution(skir.DataValue value) {
    if (_configurationIssues(value).isNotEmpty) return null;
    final realm = value.editorValueAt(editorRootPath.field("realm"))!;
    final engine = value.editorValueAt(editorRootPath.field("engine"))!;
    return skir.HostExecutionConfiguration(
      realm: _actualType(realm) == _realmHosted
          ? skir.HostedRealmConfiguration(
              primaryEngine: _decodeTarget(
                _draftString(realm, "target"),
                _realmTargets,
              )!.toSkir(),
            )
          : null,
      primaryEngine: _actualType(engine) == _engineEnabled
          ? skir.HostedEngineConfiguration(
              target: _decodeTarget(
                _draftString(engine, "target"),
                _engineTargets,
              )!.toSkir(),
              realm: _usesHostedRealm(realm, engine)
                  ? skir.EngineRealmSelection.hostedRealm
                  : skir.EngineRealmSelection.createExistingRealm(
                      realmId: topology.realmInstances
                          .singleWhere(
                            (candidate) =>
                                candidate.realmId.id ==
                                    _draftString(engine, "realm") &&
                                candidate.ownerHost.id != host.hostId,
                          )
                          .realmId,
                    ),
            )
          : null,
    );
  }
}

skir.TypeDefinitionId? _actualType(skir.DataValue value) => switch (value) {
  skir.DataValue_namedWrapper(:final value) => value.actualType.definition,
  _ => null,
};

String? _draftString(skir.DataValue value, String field) =>
    value.editorValueAt(editorRootPath.field(field))?.authoredString;

bool _usesHostedRealm(skir.DataValue realm, skir.DataValue engine) =>
    _actualType(realm) == _realmHosted &&
    _actualType(engine) == _engineEnabled &&
    (_draftString(realm, "target")?.isNotEmpty ?? false) &&
    _draftString(realm, "target") == _draftString(engine, "target");
