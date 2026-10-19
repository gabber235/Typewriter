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

BoundPresentationHost _topologyRuntimePortableHost({
  required String rootId,
  required Map<String, skir.DataValue> values,
  required Color color,
  required String title,
  required String identifier,
}) {
  final bindings = [
    for (final entry in values.entries)
      BoundPresentationBinding(
        id: _topologyBinding("$rootId.${entry.key}"),
        use: _portableUse(entry.value),
        read: (_) => entry.value,
      ),
  ];
  return BoundPresentationHost(
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

/// Joins captured host observations with caller owned identity and configuration
/// editors for the inspector.
///
/// Configuration toggles replace local named variants and all configuration
/// bindings share [configurationOwner]. [configurationOnly] omits identity and
/// runtime facts for a combined selection; callers supply the common targets
/// and eligible external Realms for that selection.
BoundPresentationHost topologyHostPortableHost({
  required TopologyHost host,
  required Service? service,
  required bool connected,
  required EditOwner configurationOwner,
  required EditOwner? identityOwner,
  required Map<String, List<String>> realmTargets,
  required Map<String, List<String>> engineTargets,
  required List<TopologyRealm> realms,
  bool configurationOnly = false,
}) {
  final realmEnabled = _topologyBinding("host.configuration.realm.enabled");
  final realmTarget = _topologyBinding("host.configuration.realm.target");
  final engineEnabled = _topologyBinding("host.configuration.engine.enabled");
  final engineTarget = _topologyBinding("host.configuration.engine.target");
  final engineRealm = _topologyBinding("host.configuration.engine.realm");
  final lastSeen = service?.lastSeen;
  String? selectedEngineTarget() => configurationOwner
      .value(editorRootPath.field("engine").field("target"))
      .valueOrNull
      ?.authoredString;
  bool usesHostedRealm() {
    final realm = configurationOwner
        .value(editorRootPath.field("realm"))
        .valueOrNull;
    final engine = configurationOwner
        .value(editorRootPath.field("engine"))
        .valueOrNull;
    return realm != null && engine != null && _usesHostedRealm(realm, engine);
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
  final bindings = <BoundPresentationBinding>[
    if (!configurationOnly) ...[
      for (final entry in runtime.entries)
        BoundPresentationBinding(
          id: _topologyBinding(entry.key),
          use: _portableUse(entry.value),
          read: (_) => entry.value,
        ),
      BoundPresentationBinding(
        id: _serviceNameBinding,
        use: _portableTextType,
        owner: identityOwner,
        read: (_) {
          if (identityOwner == null) {
            return skir.DataValue.wrapStringValue(
              service?.displayName ?? host.hostId.id,
            );
          }
          final value = identityOwner
              .value(editorRootPath.field("name"))
              .valueOrNull;
          return value is skir.DataValue_stringValueWrapper
              ? value
              : skir.DataValue.unfilled;
        },
        write: identityOwner == null
            ? null
            : (path, value) => _writeBoundString(
                _serviceNameBinding,
                identityOwner,
                editorRootPath.field("name"),
                path,
                value,
              ),
      ),
    ],
    _configurationToggle(
      id: realmEnabled,
      owner: configurationOwner,
      field: "realm",
      enabled: _draftVariant(_realmHosted, {
        "target": skir.DataValue.wrapStringValue(""),
      }),
      disabled: _realmDisabled,
    ),
    _configurationString(
      id: realmTarget,
      owner: configurationOwner,
      path: editorRootPath.field("realm").field("target"),
    ),
    _configurationToggle(
      id: engineEnabled,
      owner: configurationOwner,
      field: "engine",
      enabled: _draftVariant(_engineEnabled, {
        "target": skir.DataValue.wrapStringValue(""),
        "realm": skir.DataValue.wrapStringValue(""),
      }),
      disabled: _engineDisabled,
    ),
    _configurationString(
      id: engineTarget,
      owner: configurationOwner,
      path: editorRootPath.field("engine").field("target"),
    ),
    _configurationString(
      id: engineRealm,
      owner: configurationOwner,
      path: editorRootPath.field("engine").field("realm"),
    ),
  ];

  return BoundPresentationHost(
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
              mappings: _serviceNameMappings,
              characterFilters: _serviceNameFilters,
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
                          options: null,
                        ),
                      ),
                      skir.StatusCase(
                        match: skir.DataValue.wrapBoolean(false),
                        appearance: skir.StatusAppearance(
                          tone: skir.StatusTone.inactive,
                          label: _portableLiteral("Unavailable"),
                          options: null,
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
                            options: null,
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
                      _TopologySelectOption(
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
  );
}

BoundPresentationBinding _configurationToggle({
  required skir.ExpressionBindingId id,
  required EditOwner owner,
  required String field,
  required skir.DataValue enabled,
  required skir.TypeDefinitionId disabled,
}) => BoundPresentationBinding(
  id: id,
  use: _portableBooleanType,
  owner: owner,
  control: owner is EditingControlOwner
      ? (owner as EditingControlOwner).bindControl()
      : null,
  read: (_) {
    final current = owner.value(editorRootPath.field(field)).valueOrNull;
    return skir.DataValue.wrapBoolean(
      current != null && _actualType(current) == _actualType(enabled),
    );
  },
  write: (path, value) {
    if (path.segments.isNotEmpty || value is! skir.DataValue_booleanWrapper) {
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "invalid_value",
          message: "The workload mode is invalid",
          severity: skir.DiagnosticSeverity.error,
          targets: [
            PortableDiagnosticTarget.binding(
              skir.BindingRef(bindingId: id, path: path),
            ),
          ],
        ),
      ]);
    }
    return owner
        .update(
          editorRootPath.field(field),
          value.value ? enabled : _draftVariant(disabled),
        )
        .toPortablePresentationResult(
          binding: id,
          sourcePath: editorRootPath.field(field),
        );
  },
);

BoundPresentationBinding _configurationString({
  required skir.ExpressionBindingId id,
  required EditOwner owner,
  required skir.ValuePath path,
}) => BoundPresentationBinding(
  id: id,
  use: _portableTextType,
  owner: owner,
  control: owner is EditingControlOwner
      ? (owner as EditingControlOwner).bindControl()
      : null,
  read: (_) => skir.DataValue.wrapStringValue(
    owner.value(path).valueOrNull?.authoredString ?? "",
  ),
  write: (suffix, value) => _writeBoundString(id, owner, path, suffix, value),
);

PortablePresentationWriteResult _writeBoundString(
  skir.ExpressionBindingId id,
  EditOwner owner,
  skir.ValuePath path,
  skir.ValuePath suffix,
  skir.DataValue value,
) {
  if (suffix.segments.isNotEmpty ||
      value is! skir.DataValue_stringValueWrapper) {
    return PortablePresentationWriteResult.rejected([
      PortablePresentationDiagnostic(
        code: "invalid_value",
        message: "The selected value is invalid",
        severity: skir.DiagnosticSeverity.error,
        targets: [
          PortableDiagnosticTarget.binding(
            skir.BindingRef(bindingId: id, path: suffix),
          ),
        ],
      ),
    ]);
  }
  return owner
      .update(path, value)
      .toPortablePresentationResult(binding: id, sourcePath: path);
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

/// One option offered by a topology select input.
@freezed
abstract class _TopologySelectOption with _$TopologySelectOption {
  const factory _TopologySelectOption({
    required String id,
    required String label,
    required String value,
  }) = __TopologySelectOption;
}

List<_TopologySelectOption> _targetOptions(
  Map<String, List<String>> targets,
) => [
  for (final entry in targets.entries)
    for (final version in entry.value)
      _TopologySelectOption(
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
  List<_TopologySelectOption> options,
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
          content: null,
          enabledIf: null,
          disabledReason: null,
        ),
    ],
    allowCustomValue: false,
    appearance: null,
    content: null,
    popup: null,
    optionsConfig: null,
  ),
  header: null,
);

/// Builds the observational inspector without introducing another mutation owner.
extension RealmPortablePresentation on TopologyRealm {
  BoundPresentationHost portablePresentationHost() =>
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
  BoundPresentationHost portablePresentationHost() =>
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
