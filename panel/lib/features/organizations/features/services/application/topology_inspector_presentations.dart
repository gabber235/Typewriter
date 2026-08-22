part of "services.dart";

PresentationDefinition _hostInspectorPresentation({
  required Map<String, List<int>> realmTargets,
  required Map<String, List<int>> engineTargets,
  required List<skir.RealmInstance> realms,
  required bool canHostRealm,
}) => PresentationDefinition(
  id: _hostInspectorPresentationId,
  target: NamedType(_hostInspectorTypeRef),
  root: PresentationNode(
    id: "serviceHost.inspector",
    element: ColumnElement(
      spacing: 16,
      crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
      children: [
        PresentationNode(
          id: "serviceHost.service",
          header: PresentationHeader(
            title: "Service Details".asStringLiteral.asHeaderTitle,
          ),
          element: ColumnElement(
            spacing: 12,
            crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
            children: [
              PresentationNode(
                id: "serviceHost.service.name",
                element: TextInputElement(
                  control: _hostControl(
                    _hostPath(
                      _HostInspectorFields.service,
                      _HostInspectorFields.name,
                    ),
                    "Name",
                  ),
                  multiline: false,
                  inputFormatters: identifierInputFormats,
                ),
              ),
              for (final field in const [
                (_HostInspectorFields.version, "Version"),
                (_HostInspectorFields.state, "State"),
                (_HostInspectorFields.lastSeen, "Last seen"),
              ])
                _hostReadOnlyField(
                  id: "serviceHost.service.${field.$1}",
                  path: _hostPath(_HostInspectorFields.service, field.$1),
                  label: field.$2,
                ),
            ],
          ),
        ),
        PresentationNode(
          id: "serviceHost.host",
          header: PresentationHeader(
            title: "Service Host Details".asStringLiteral.asHeaderTitle,
          ),
          element: ColumnElement(
            spacing: 12,
            crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
            children: [
              _hostReadOnlyField(
                id: "serviceHost.host.entrypoint",
                path: _hostPath(
                  _HostInspectorFields.host,
                  _HostInspectorFields.entrypoint,
                ),
                label: "Entry point",
              ),
              _hostReadOnlyField(
                id: "serviceHost.host.canHostRealm",
                path: _hostPath(
                  _HostInspectorFields.host,
                  _HostInspectorFields.canHostRealm,
                ),
                label: "Can host a Realm",
                boolean: true,
              ),
              _hostReadOnlyField(
                id: "serviceHost.host.supportedEngines",
                path: _hostPath(
                  _HostInspectorFields.host,
                  _HostInspectorFields.supportedEngines,
                ),
                label: "Supported engines",
                list: true,
              ),
              for (final field in const [
                (_HostInspectorFields.state, "State"),
                (_HostInspectorFields.message, "Message"),
                (_HostInspectorFields.updatedAt, "Updated at"),
              ])
                _hostReadOnlyField(
                  id: "serviceHost.host.${field.$1}",
                  path: _hostPath(_HostInspectorFields.host, field.$1),
                  label: field.$2,
                ),
            ],
          ),
        ),
        PresentationNode(
          id: "serviceHost.configuration",
          header: PresentationHeader(
            title: "Configuration".asStringLiteral.asHeaderTitle,
          ),
          element: ColumnElement(
            spacing: 12,
            crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
            children: [
              if (canHostRealm) ...[
                PresentationNode(
                  id: "serviceHost.realmEnabled",
                  element: ToggleInputElement(
                    _configurationControl(
                      _HostInspectorFields.realmEnabled,
                      "Host a Realm",
                    ),
                  ),
                ),
                PresentationNode(
                  id: "serviceHost.realmConfiguration",
                  element: ConditionalElement(
                    condition: _configurationExpression(
                      _HostInspectorFields.realmEnabled,
                      const BooleanType(),
                    ),
                    whenTrue: _engineTargetSelect(
                      id: "serviceHost.realmTarget",
                      field: _HostInspectorFields.realmTarget,
                      label: "Realm target",
                      targets: realmTargets,
                    ),
                  ),
                ),
              ],
              PresentationNode(
                id: "serviceHost.engineEnabled",
                element: ToggleInputElement(
                  _configurationControl(
                    _HostInspectorFields.engineEnabled,
                    "Run an execution engine",
                  ),
                ),
              ),
              PresentationNode(
                id: "serviceHost.engineConfiguration",
                element: ConditionalElement(
                  condition: _configurationExpression(
                    _HostInspectorFields.engineEnabled,
                    const BooleanType(),
                  ),
                  whenTrue: PresentationNode(
                    id: "serviceHost.engineConfiguration.fields",
                    element: ColumnElement(
                      spacing: 12,
                      crossAxisAlignment:
                          PresentationCrossAxisAlignment.stretch,
                      children: [
                        _engineTargetSelect(
                          id: "serviceHost.engineTarget",
                          field: _HostInspectorFields.engineTarget,
                          label: "Engine target",
                          targets: engineTargets,
                        ),
                        PresentationNode(
                          id: "serviceHost.realmAssignment",
                          element: canHostRealm
                              ? ConditionalElement(
                                  condition: _configurationExpression(
                                    _HostInspectorFields.realmEnabled,
                                    const BooleanType(),
                                  ),
                                  whenTrue: _realmAssignmentSelect(
                                    id: "serviceHost.realmAssignment.hosted",
                                    realms: realms,
                                    includeHosted: true,
                                  ),
                                  whenFalse: _realmAssignmentSelect(
                                    id: "serviceHost.realmAssignment.remote",
                                    realms: realms,
                                  ),
                                )
                              : _realmAssignmentSelect(
                                  id: "serviceHost.realmAssignment.remote",
                                  realms: realms,
                                ).element,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

PresentationNode _realmAssignmentSelect({
  required String id,
  required List<skir.RealmInstance> realms,
  bool includeHosted = false,
}) => PresentationNode(
  id: id,
  element: SelectInputElement(
    control: _configurationControl(
      _HostInspectorFields.realmAssignment,
      "Assigned Realm",
    ),
    options: [
      if (includeHosted)
        const SelectOption(
          id: "hosted",
          label: TypedExpression(
            resultType: StringType(),
            expression: LiteralExpression(StringValue("Hosted Realm")),
          ),
          value: TypedExpression(
            resultType: StringType(),
            expression: LiteralExpression(StringValue("hosted")),
          ),
        ),
      for (final realm in realms)
        SelectOption(
          id: realm.realmId.id,
          label: realm.ownerHost.name.formatted.asStringLiteral,
          value: realm.realmId.id.asStringLiteral,
        ),
    ],
  ),
);

final _realmInstanceInspectorPresentation = _runtimeInspectorPresentation(
  id: _realmInstanceInspectorPresentationId,
  target: _realmInstanceInspectorTypeRef,
  rootId: "realmInstance.inspector",
  fields: const [
    (_RuntimeInspectorFields.ownerHost, "Owner host"),
    (_RuntimeInspectorFields.target, "Target"),
    (_RuntimeInspectorFields.manifestRevision, "Manifest revision"),
    (_RuntimeInspectorFields.runtimeStatus, "Status"),
    (_RuntimeInspectorFields.artifactVersion, "Artifact version"),
    (_RuntimeInspectorFields.runtimeMessage, "Message"),
    (_RuntimeInspectorFields.updatedAt, "Updated at"),
  ],
);

final _engineInstanceInspectorPresentation = _runtimeInspectorPresentation(
  id: _engineInstanceInspectorPresentationId,
  target: _engineInstanceInspectorTypeRef,
  rootId: "engineInstance.inspector",
  fields: const [
    (_RuntimeInspectorFields.ownerHost, "Owner host"),
    (_RuntimeInspectorFields.assignedRealm, "Assigned Realm"),
    (_RuntimeInspectorFields.target, "Target"),
    (_RuntimeInspectorFields.manifestRevision, "Manifest revision"),
    (_RuntimeInspectorFields.runtimeStatus, "Status"),
    (_RuntimeInspectorFields.artifactVersion, "Artifact version"),
    (_RuntimeInspectorFields.runtimeMessage, "Message"),
    (_RuntimeInspectorFields.updatedAt, "Updated at"),
  ],
);

PresentationDefinition _runtimeInspectorPresentation({
  required PresentationId id,
  required ResolvedTypeRef target,
  required String rootId,
  required List<(String, String)> fields,
}) => PresentationDefinition(
  id: id,
  target: NamedType(target),
  root: _inspectorSection(id: rootId, title: "Runtime", fields: fields),
);

PresentationNode _inspectorSection({
  required String id,
  required String title,
  required List<(String, String)> fields,
}) => PresentationNode(
  id: id,
  header: PresentationHeader(title: title.asStringLiteral.asHeaderTitle),
  properties: const PresentationProperties(readOnly: true),
  element: ColumnElement(
    spacing: 12,
    crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
    children: [
      for (final (field, label) in fields)
        PresentationNode(
          id: "$id.$field",
          header: PresentationHeader(
            title: label.asStringLiteral.asHeaderTitle,
          ),
          element: TextElement(_fieldExpression(field, const StringType())),
        ),
    ],
  ),
);

PresentationNode _hostReadOnlyField({
  required String id,
  required DataPath path,
  required String label,
  bool boolean = false,
  bool list = false,
}) => PresentationNode(
  id: id,
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(title: label.asStringLiteral.asHeaderTitle),
  element: boolean
      ? ConditionalElement(
          condition: _hostExpression(path, const BooleanType()),
          whenTrue: PresentationNode(
            id: "$id.yes",
            element: TextElement("Yes".asStringLiteral),
          ),
          whenFalse: PresentationNode(
            id: "$id.no",
            element: TextElement("No".asStringLiteral),
          ),
        )
      : list
      ? RepeatedElement(
          source: _hostExpression(path, _stringListType),
          itemBindingId: const BindingId(71),
          presentation: SequencePresentation(
            layout: PresentationSequenceLayout.children(
              PresentationChildrenLayout.column(spacing: 4),
            ),
            item: PresentationNode(
              id: "$id.item",
              element: TextElement(
                const TypedExpression(
                  resultType: StringType(),
                  expression: BindingExpression(
                    BindingReference(bindingId: BindingId(71)),
                  ),
                ),
              ),
            ),
          ),
        )
      : TextElement(_hostExpression(path, const StringType())),
);

PresentationNode _engineTargetSelect({
  required String id,
  required String field,
  required String label,
  required Map<String, List<int>> targets,
}) => PresentationNode(
  id: id,
  element: SelectInputElement(
    control: _configurationControl(field, label),
    options: [
      for (final entry in targets.entries)
        for (final version in entry.value)
          SelectOption(
            id: _encodeTarget(entry.key, version),
            label: "${entry.key.formatted} $version.x".asStringLiteral,
            value: _encodeTarget(entry.key, version).asStringLiteral,
          ),
    ],
  ),
);

DataPath _hostPath(String section, String field) =>
    DataPath.root.field(section).field(field);

DataPath _configurationPath(String field) =>
    _hostPath(_HostInspectorFields.configuration, field);

BoundControl _configurationControl(String field, String label) =>
    _hostControl(_configurationPath(field), label);

TypedExpression _configurationExpression(String field, TypeExpression type) =>
    _hostExpression(_configurationPath(field), type);

BoundControl _hostControl(DataPath path, String label) => BoundControl(
  binding: BindingReference(bindingId: const BindingId(0), path: path),
  label: label.asStringLiteral,
);

TypedExpression _hostExpression(DataPath path, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(bindingId: const BindingId(0), path: path),
      ),
    );

TypedExpression _fieldExpression(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: const BindingId(0),
          path: DataPath.root.field(name),
        ),
      ),
    );
