part of "services.dart";

final _portableBooleanType = skir.TypeUse.wrapScalar(skir.ScalarKind.boolean);

abstract final class _RuntimeInspectorFields {
  static const ownerHost = "ownerHost";
  static const target = "target";
  static const assignedRealm = "assignedRealm";
  static const runtimeStatus = "runtimeStatus";
  static const artifactVersion = "artifactVersion";
  static const runtimeMessage = "runtimeMessage";
  static const updatedAt = "updatedAt";
}

skir.ExpressionBindingId _topologyBinding(String value) =>
    skir.ExpressionBindingId(value: value);

EditorSourcePresentationHost topologyRuntimePortableHost({
  required String rootId,
  required Map<String, skir.DataValue> values,
}) {
  final displayValues = values.map(
    (key, value) => MapEntry(key, _portableDisplayValue(value)),
  );
  final bindings = [
    for (final entry in displayValues.entries)
      EditorSourcePresentationBinding(
        id: _topologyBinding("$rootId.${entry.key}"),
        use: _portableUse(entry.value),
        read: (_) => entry.value,
      ),
  ];
  return EditorSourcePresentationHost(
    catalog: _servicePortableCatalog,
    root: () => _portableColumn(rootId, [
      for (final entry in displayValues.entries)
        _portableFact(
          "$rootId.${entry.key}",
          _topologyLabel(entry.key),
          _topologyBinding("$rootId.${entry.key}"),
        ),
    ]),
    bindings: bindings,
    budget: skir.EvaluationBudget(maxSteps: 512, maxCollectionItems: 64),
    readOnly: true,
  );
}

EditorSourcePresentationHost topologyHostPortableHost({
  required TopologyHost host,
  required Service? service,
  required bool connected,
  required EditOwner configurationOwner,
  required EditOwner? identityOwner,
  required Map<String, List<String>> realmTargets,
  required Map<String, List<String>> engineTargets,
  required List<TopologyRealm> realms,
  bool configurationOnly = false,
  Future<void> Function()? commit,
}) {
  final realmEnabled = _topologyBinding("host.configuration.realm.enabled");
  final realmTarget = _topologyBinding("host.configuration.realm.target");
  final engineEnabled = _topologyBinding("host.configuration.engine.enabled");
  final engineTarget = _topologyBinding("host.configuration.engine.target");
  final engineRealm = _topologyBinding("host.configuration.engine.realm");
  final lastSeen = service?.lastSeen;
  String? selectedEngineTarget() => configurationOwner
      .value(DataPath.root.field("engine").field("target"))
      .valueOrNull
      ?.asStringOrNull;
  bool usesHostedRealm() {
    final realm = configurationOwner
        .value(DataPath.root.field("realm"))
        .valueOrNull;
    final engine = configurationOwner
        .value(DataPath.root.field("engine"))
        .valueOrNull;
    return realm is PolymorphicValue &&
        engine is PolymorphicValue &&
        _usesHostedRealm(realm, engine);
  }

  final runtime = <String, skir.DataValue>{
    "service.version": skir.DataValue.wrapStringValue(
      service?.role.version ?? "Unavailable",
    ),
    "service.state": skir.DataValue.wrapStringValue(
      connected ? "Connected" : "Offline",
    ),
    "service.last_seen": lastSeen == null
        ? skir.DataValue.wrapStringValue("Never")
        : skir.DataValue.wrapStringValue(lastSeen.toIso8601String()),
    "host.entrypoint": skir.DataValue.wrapStringValue(
      host.entrypoint.formatted,
    ),
    "host.can_host_realm": skir.DataValue.wrapStringValue(
      host.canHostRealm ? "Available" : "Unavailable",
    ),
    "host.supported_engines": skir.DataValue.wrapStringValue(
      host.supportedEngines.map((value) => value.engineId).join(", "),
    ),
    "host.state": skir.DataValue.wrapStringValue(
      hostRuntimeStatusLabel(host.state.status),
    ),
    "host.message": skir.DataValue.wrapStringValue(
      host.state.message ?? "None",
    ),
    "host.updated_at": skir.DataValue.wrapStringValue(
      host.state.updatedAt.toIso8601String(),
    ),
  };
  final bindings = <EditorSourcePresentationBinding>[
    if (!configurationOnly) ...[
      for (final entry in runtime.entries)
        EditorSourcePresentationBinding(
          id: _topologyBinding(entry.key),
          use: _portableUse(entry.value),
          read: (_) => entry.value,
        ),
      EditorSourcePresentationBinding(
        id: _serviceNameBinding,
        use: _portableTextType,
        owner: identityOwner,
        read: (_) => identityOwner == null
            ? skir.DataValue.wrapStringValue("Unavailable")
            : switch (identityOwner
                  .value(DataPath.root.field("name"))
                  .valueOrNull) {
                StringValue(:final value) => skir.DataValue.wrapStringValue(
                  value,
                ),
                _ => skir.DataValue.unfilled,
              },
        write: identityOwner == null
            ? null
            : (path, value) => _writeLegacyString(
                identityOwner,
                DataPath.root.field("name"),
                path,
                value,
              ),
      ),
    ],
    _configurationToggle(
      id: realmEnabled,
      owner: configurationOwner,
      field: "realm",
      enabled: _realmHosted,
      disabled: _realmDisabled,
    ),
    _configurationString(
      id: realmTarget,
      owner: configurationOwner,
      path: DataPath.root.field("realm").field("target"),
    ),
    _configurationToggle(
      id: engineEnabled,
      owner: configurationOwner,
      field: "engine",
      enabled: _engineEnabled,
      disabled: _engineDisabled,
    ),
    _configurationString(
      id: engineTarget,
      owner: configurationOwner,
      path: DataPath.root.field("engine").field("target"),
    ),
    _configurationString(
      id: engineRealm,
      owner: configurationOwner,
      path: DataPath.root.field("engine").field("realm"),
    ),
  ];

  return EditorSourcePresentationHost(
    catalog: _servicePortableCatalog,
    root: () => _portableColumn("serviceHost", [
      if (!configurationOnly) ...[
        if (identityOwner == null)
          _portableFact("serviceHost.name", "Name", _serviceNameBinding)
        else
          _portableTextInput(
            "serviceHost.name",
            _serviceNameBinding,
            label: "Name",
            inputFormatters: [
              skir.TextInputFormat.lowercase,
              skir.TextInputFormat.createReplace(
                pattern: r"[\s\-]+",
                replacement: "_",
              ),
              skir.TextInputFormat.wrapAllow("[a-z0-9_]"),
            ],
          ),
        for (final entry in runtime.entries)
          _portableFact(
            "serviceHost.${entry.key}",
            _topologyLabel(entry.key),
            _topologyBinding(entry.key),
          ),
      ],
      if (host.canHostRealm) ...[
        _portableToggle(
          "serviceHost.realm.enabled",
          realmEnabled,
          "Host a Realm",
        ),
        _portableConditional(
          "serviceHost.realm.options",
          realmEnabled,
          _portableSelect(
            "serviceHost.realm.target",
            realmTarget,
            "Realm target",
            _targetOptions(realmTargets),
          ),
        ),
      ],
      _portableToggle(
        "serviceHost.engine.enabled",
        engineEnabled,
        "Run an execution engine",
      ),
      _portableConditional(
        "serviceHost.engine.options",
        engineEnabled,
        _portableColumn("serviceHost.engine.fields", [
          _portableSelect(
            "serviceHost.engine.target",
            engineTarget,
            "Engine target",
            _targetOptions(engineTargets),
          ),
          if (!usesHostedRealm())
            _portableSelect(
              "serviceHost.engine.realm",
              engineRealm,
              "Assigned Realm",
              [
                for (final realm in realms)
                  if (_encodeTarget(
                        realm.targetEngine.engineId,
                        realm.targetEngine.versionConstraint,
                      ) ==
                      selectedEngineTarget())
                    (
                      id: realm.realmId.id,
                      label: realm.ownerHost.name.formatted,
                      value: realm.realmId.id,
                    ),
              ],
            ),
        ]),
      ),
      _portableCommit("serviceHost.save", engineEnabled),
    ]),
    bindings: bindings,
    budget: skir.EvaluationBudget(maxSteps: 1024, maxCollectionItems: 128),
    capabilities: commit == null
        ? configurationOwner.portablePresentationCapabilities
        : PortablePresentationCapabilities(commit: commit),
  );
}

EditorSourcePresentationBinding _configurationToggle({
  required skir.ExpressionBindingId id,
  required EditOwner owner,
  required String field,
  required ResolvedTypeRef enabled,
  required ResolvedTypeRef disabled,
}) => EditorSourcePresentationBinding(
  id: id,
  use: _portableBooleanType,
  owner: owner,
  read: (_) {
    final current = owner.value(DataPath.root.field(field)).valueOrNull;
    return skir.DataValue.wrapBoolean(
      current is PolymorphicValue && current.concreteType == enabled,
    );
  },
  write: (path, value) {
    if (path.segments.isNotEmpty || value is! skir.DataValue_booleanWrapper) {
      return const PortablePresentationWriteResult.rejected(
        "The workload mode is invalid",
      );
    }
    return owner
        .update(
          DataPath.root.field(field),
          _draftVariant(value.value ? enabled : disabled),
        )
        .portablePresentationResult;
  },
);

EditorSourcePresentationBinding _configurationString({
  required skir.ExpressionBindingId id,
  required EditOwner owner,
  required DataPath path,
}) => EditorSourcePresentationBinding(
  id: id,
  use: _portableTextType,
  owner: owner,
  read: (_) => switch (owner.value(path).valueOrNull) {
    StringValue(:final value) => skir.DataValue.wrapStringValue(value),
    _ => skir.DataValue.wrapStringValue(""),
  },
  write: (suffix, value) => _writeLegacyString(owner, path, suffix, value),
);

PortablePresentationWriteResult _writeLegacyString(
  EditOwner owner,
  DataPath path,
  skir.ValuePath suffix,
  skir.DataValue value,
) {
  if (suffix.segments.isNotEmpty ||
      value is! skir.DataValue_stringValueWrapper) {
    return const PortablePresentationWriteResult.rejected(
      "The selected value is invalid",
    );
  }
  return owner
      .update(path, StringValue(value.value))
      .portablePresentationResult;
}

skir.TypeUse _portableUse(skir.DataValue value) {
  if (value is skir.DataValue_booleanWrapper) return _portableBooleanType;
  if (value is skir.DataValue_timestampWrapper) return _portableTimestampType;
  if (value == skir.DataValue.null_) return _portableOptionalTimestampType;
  return _portableTextType;
}

String _topologyLabel(String field) {
  final name = field.split(".").last;
  return switch (name) {
    "version" => "Version",
    "state" => field.startsWith("service.") ? "Connection" : "Runtime health",
    "last_seen" => "Last seen",
    "entrypoint" => "Entry point",
    "can_host_realm" => "Realm hosting",
    "supported_engines" => "Supported engines",
    "message" || "runtimeMessage" => "Message",
    "updated_at" || "updatedAt" => "Updated",
    "ownerHost" => "Owner host",
    "assignedRealm" => "Assigned Realm",
    "target" => "Target",
    "runtimeStatus" => "Status",
    "artifactVersion" => "Artifact version",
    _ =>
      name
          .split("_")
          .mapIndexed(
            (index, value) => index == 0
                ? "${value.substring(0, 1).toUpperCase()}${value.substring(1)}"
                : value,
          )
          .join(" "),
  };
}

skir.DataValue _portableDisplayValue(skir.DataValue value) =>
    skir.DataValue.wrapStringValue(switch (value) {
      skir.DataValue_stringValueWrapper(:final value) => value,
      skir.DataValue_booleanWrapper(:final value) =>
        value ? "Available" : "Unavailable",
      skir.DataValue_timestampWrapper(:final value) => value.toIso8601String(),
      skir.DataValue_integerWrapper(:final value) => value,
      skir.DataValue_floatWrapper(:final value) => value.toString(),
      skir.DataValue_decimalWrapper(:final value) => value,
      final current when current == skir.DataValue.null_ => "None",
      final current when current == skir.DataValue.unfilled => "Unavailable",
      _ => "Unavailable",
    });

List<({String id, String label, String value})> _targetOptions(
  Map<String, List<String>> targets,
) => [
  for (final entry in targets.entries)
    for (final version in entry.value)
      (
        id: _encodeTarget(entry.key, version),
        label: _targetLabel(
          TopologyEngineTarget(engineId: entry.key, versionConstraint: version),
        ),
        value: _encodeTarget(entry.key, version),
      ),
];

skir.PresentationNode _portableToggle(
  String id,
  skir.ExpressionBindingId bindingId,
  String label,
) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createToggleInput(
    binding: _portableReference(bindingId),
    label: _portableLiteral(label),
    description: null,
    prefix: null,
    semanticLabel: _portableLiteral(label),
  ),
  header: null,
);

skir.PresentationNode _portableSelect(
  String id,
  skir.ExpressionBindingId bindingId,
  String label,
  List<({String id, String label, String value})> options,
) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createSelectInput(
    control: skir.BoundControl(
      binding: _portableReference(bindingId),
      label: _portableLiteral(label),
      description: null,
      prefix: null,
      semanticLabel: _portableLiteral(label),
    ),
    options: [
      for (final option in options)
        skir.SelectOption(
          optionId: option.id,
          label: _portableLiteral(option.label),
          value: _portableLiteral(option.value),
        ),
    ],
    allowCustomValue: false,
  ),
  header: null,
);

skir.PresentationNode _portableConditional(
  String id,
  skir.ExpressionBindingId bindingId,
  skir.PresentationNode child,
) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createConditional(
    condition: _portableRead(bindingId),
    whenTrue: child,
    whenFalse: null,
  ),
  header: null,
);
