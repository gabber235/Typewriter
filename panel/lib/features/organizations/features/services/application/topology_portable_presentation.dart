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

EditorSourcePresentationHost _topologyRuntimePortableHost({
  required String rootId,
  required Map<String, skir.DataValue> values,
  required Color color,
  required String title,
  required String identifier,
}) {
  final bindings = [
    for (final entry in values.entries)
      EditorSourcePresentationBinding(
        id: _topologyBinding("$rootId.${entry.key}"),
        use: _portableUse(entry.value),
        read: (_) => entry.value,
      ),
  ];
  return EditorSourcePresentationHost(
    catalog: _servicePortableCatalog,
    root: () => _portableColumn(rootId, [
      title.portableExpression.resourceHeading(
        id: "$rootId.heading",
        color: color.portableExpression,
        identifier: identifier.portableExpression,
      ),
      _inspectorSection("$rootId.overview", "Runtime", [
        _inspectorCard("$rootId.health", "STATUS", color, [
          _inspectorRuntimeStatus(
            "$rootId.status",
            _topologyBinding(
              "$rootId.${_RuntimeInspectorFields.runtimeStatus}",
            ),
          ),
          _portableFact(
            "$rootId.artifact",
            "Artifact",
            _topologyBinding(
              "$rootId.${_RuntimeInspectorFields.artifactVersion}",
            ),
          ),
          _inspectorFact(
            "$rootId.updated",
            "Updated",
            _inspectorDateTime(
              _topologyBinding("$rootId.${_RuntimeInspectorFields.updatedAt}"),
            ),
          ),
          _inspectorMessage(
            "$rootId.message",
            _topologyBinding(
              "$rootId.${_RuntimeInspectorFields.runtimeMessage}",
            ),
          ),
        ]),
      ]),
      _inspectorSection("$rootId.placement", "Placement", [
        _inspectorCard("$rootId.assignment", "ASSIGNMENT", color, [
          for (final field in [
            _RuntimeInspectorFields.ownerHost,
            _RuntimeInspectorFields.assignedRealm,
            _RuntimeInspectorFields.target,
          ])
            if (values.containsKey(field))
              _portableFact(
                "$rootId.$field",
                _topologyLabel(field),
                _topologyBinding("$rootId.$field"),
              ),
        ]),
      ]),
    ], spacing: 16),
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
        ? skir.DataValue.null_
        : skir.DataValue.wrapTimestamp(lastSeen),
    "host.entrypoint": skir.DataValue.wrapStringValue(
      host.entrypoint.formatted,
    ),
    "host.can_host_realm": skir.DataValue.wrapBoolean(host.canHostRealm),
    "host.state": skir.DataValue.wrapStringValue(host.state.status.name),
    "host.message": skir.DataValue.wrapStringValue(
      host.state.message ?? "None",
    ),
    "host.updated_at": skir.DataValue.wrapTimestamp(host.state.updatedAt),
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
            ? skir.DataValue.wrapStringValue(
                service?.displayName ?? host.hostId.id,
              )
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
      enabled: _draftVariant(_realmHosted, {"target": "".asValue}),
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
      enabled: _draftVariant(_engineEnabled, {
        "target": "".asValue,
        "realm": "".asValue,
      }),
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
      if (!configurationOnly)
        _serviceNameBinding.readExpression().resourceHeading(
          id: "serviceHost.heading",
          color: (service?.color ?? standaloneServiceColor).portableExpression,
          identifier: host.hostId.id.portableExpression,
        ),
      if (!configurationOnly) ...[
        _inspectorSection("serviceHost.service", "Service", [
          if (identityOwner == null)
            _portableFact("serviceHost.name", "Name", _serviceNameBinding)
          else
            _portableTextInput(
              "serviceHost.name",
              _serviceNameBinding,
              label: "Name",
              inputFormatters: _serviceNameInputFormats,
            ),
          _inspectorCard(
            "serviceHost.connection",
            "CONNECTION",
            service?.color ?? standaloneServiceColor,
            [
              _inspectorConnectionStatus(
                "serviceHost.connection.status",
                _topologyBinding("service.state"),
              ),
              _inspectorGrid("serviceHost.connection.facts", [
                _portableFact(
                  "serviceHost.version",
                  "Version",
                  _topologyBinding("service.version"),
                ),
                _inspectorFact(
                  "serviceHost.lastSeen",
                  "Last seen",
                  _inspectorRelativeTime(_topologyBinding("service.last_seen")),
                ),
              ]),
            ],
          ),
        ]),
        _inspectorSection("serviceHost.host", "Host", [
          _inspectorCard(
            "serviceHost.capabilities",
            "CAPABILITIES",
            service?.color ?? standaloneServiceColor,
            [
              _inspectorGrid("serviceHost.capabilityFacts", [
                _portableFact(
                  "serviceHost.entrypoint",
                  "Entry point",
                  _topologyBinding("host.entrypoint"),
                ),
                _inspectorFact(
                  "serviceHost.realmHosting",
                  "Realm hosting",
                  skir.PresentationElement.createStatus(
                    value: _portableRead(
                      _topologyBinding("host.can_host_realm"),
                    ),
                    cases: [
                      skir.StatusCase(
                        match: skir.DataValue.wrapBoolean(true),
                        appearance: skir.StatusAppearance(
                          tone: skir.StatusTone.active,
                          label: _portableLiteral("Available"),
                        ),
                      ),
                      skir.StatusCase(
                        match: skir.DataValue.wrapBoolean(false),
                        appearance: skir.StatusAppearance(
                          tone: skir.StatusTone.inactive,
                          label: _portableLiteral("Unavailable"),
                        ),
                      ),
                    ],
                    fallback: null,
                  ),
                ),
              ]),
              _inspectorFact(
                "serviceHost.engines",
                "Supported engines",
                skir.PresentationElement.wrapChildren(
                  skir.ChildrenElement.createWrap(
                    layout: skir.WrapChildrenLayout(
                      spacing: 6,
                      runSpacing: 6,
                      mainAxisAlignment: skir.MainAxisAlignment.start,
                      crossAxisAlignment: skir.CrossAxisAlignment.start,
                    ),
                    children: [
                      for (final engine in host.supportedEngines)
                        _inspectorNode(
                          "serviceHost.engine.${engine.engineId}",
                          skir.PresentationElement.createChip(
                            label: _portableLiteral(engine.engineId),
                            color: _inspectorColor(engineServiceRoleColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _inspectorCard(
            "serviceHost.health",
            "RUNTIME HEALTH",
            service?.color ?? standaloneServiceColor,
            [
              _inspectorHostStatus(
                "serviceHost.health.status",
                _topologyBinding("host.state"),
              ),
              _inspectorFact(
                "serviceHost.updated",
                "Updated",
                _inspectorDateTime(_topologyBinding("host.updated_at")),
              ),
              _inspectorMessage(
                "serviceHost.message",
                _topologyBinding("host.message"),
              ),
            ],
          ),
        ]),
      ],
      _inspectorSection("serviceHost.configuration", "Configuration", [
        if (host.canHostRealm)
          _inspectorWorkload(
            "serviceHost.realm",
            "REALM HOSTING",
            "Host a Realm",
            realmServiceRoleColor,
            realmEnabled,
            [
              _portableSelect(
                "serviceHost.realm.target",
                realmTarget,
                "Realm target",
                _targetOptions(realmTargets),
              ),
            ],
          ),
        _inspectorWorkload(
          "serviceHost.engine",
          "EXECUTION ENGINE",
          "Run an execution engine",
          engineServiceRoleColor,
          engineEnabled,
          [
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
          ],
        ),
        _portableCommit("serviceHost.save", engineEnabled),
      ]),
    ], spacing: 16),
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
  required PolymorphicValue enabled,
  required ResolvedTypeRef disabled,
}) => EditorSourcePresentationBinding(
  id: id,
  use: _portableBooleanType,
  owner: owner,
  read: (_) {
    final current = owner.value(DataPath.root.field(field)).valueOrNull;
    return skir.DataValue.wrapBoolean(
      current is PolymorphicValue &&
          current.concreteType == enabled.concreteType,
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
          value.value ? enabled : _draftVariant(disabled),
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

/// Builds the observational inspector without introducing another mutation owner.
extension RealmPortablePresentation on TopologyRealm {
  EditorSourcePresentationHost portablePresentationHost() =>
      _topologyRuntimePortableHost(
        rootId: "realmInstance",
        title: ownerHost.name.formatted,
        identifier: this.realmId.id,
        color: realmServiceRoleColor,
        values: {
          _RuntimeInspectorFields.ownerHost: skir.DataValue.wrapStringValue(
            ownerHost.name.formatted,
          ),
          _RuntimeInspectorFields.target: skir.DataValue.wrapStringValue(
            _targetLabel(targetEngine),
          ),
          _RuntimeInspectorFields.runtimeStatus: skir.DataValue.wrapStringValue(
            state.status.name,
          ),
          _RuntimeInspectorFields.artifactVersion: skir
              .DataValue.wrapStringValue(state.activeArtifactVersion ?? "None"),
          _RuntimeInspectorFields.runtimeMessage:
              skir.DataValue.wrapStringValue(state.message ?? "None"),
          _RuntimeInspectorFields.updatedAt: skir.DataValue.wrapTimestamp(
            state.updatedAt,
          ),
        },
      );
}

/// Builds the observational inspector without introducing another mutation owner.
extension EnginePortablePresentation on TopologyEngine {
  EditorSourcePresentationHost portablePresentationHost() =>
      _topologyRuntimePortableHost(
        rootId: "engineInstance",
        title: "${target.engineId} engine",
        identifier: engineId.id,
        color: engineServiceRoleColor,
        values: {
          _RuntimeInspectorFields.ownerHost: skir.DataValue.wrapStringValue(
            ownerHost.name.formatted,
          ),
          _RuntimeInspectorFields.assignedRealm: skir.DataValue.wrapStringValue(
            realm.ownerHost.name.formatted,
          ),
          _RuntimeInspectorFields.target: skir.DataValue.wrapStringValue(
            _targetLabel(target),
          ),
          _RuntimeInspectorFields.runtimeStatus: skir.DataValue.wrapStringValue(
            state.status.name,
          ),
          _RuntimeInspectorFields.artifactVersion: skir
              .DataValue.wrapStringValue(state.activeArtifactVersion ?? "None"),
          _RuntimeInspectorFields.runtimeMessage:
              skir.DataValue.wrapStringValue(state.message ?? "None"),
          _RuntimeInspectorFields.updatedAt: skir.DataValue.wrapTimestamp(
            state.updatedAt,
          ),
        },
      );
}
