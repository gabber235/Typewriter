part of "services.dart";

PresentationDefinition _hostInspectorPresentation({
  required Map<String, List<int>> realmTargets,
  required Map<String, List<int>> engineTargets,
  required List<skir.RealmInstance> realms,
}) => PresentationDefinition(
  id: _hostInspectorPresentationId,
  target: NamedType(_hostInspectorTypeRef),
  root: PresentationNode(
    id: "serviceHost.inspector",
    element: ColumnElement(
      spacing: 16,
      crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
      children: [
        _inspectorSection(
          id: "serviceHost.service",
          title: "Service",
          fields: const [
            (_HostInspectorFields.serviceName, "Name"),
            (_HostInspectorFields.serviceId, "Identifier"),
            (_HostInspectorFields.serviceRoles, "Roles"),
            (_HostInspectorFields.connected, "Connected"),
          ],
        ),
        _inspectorSection(
          id: "serviceHost.runtime",
          title: "Host",
          fields: const [
            (_HostInspectorFields.entrypoint, "Entrypoint"),
            (_HostInspectorFields.runtimeStatus, "Status"),
            (_HostInspectorFields.runtimeMessage, "Message"),
            (_HostInspectorFields.topologyRevision, "Topology revision"),
            (_HostInspectorFields.supportedEngines, "Supported engines"),
          ],
        ),
        PresentationNode(
          id: "serviceHost.execution",
          header: PresentationHeader(
            title: "Execution".asStringLiteral.asHeaderTitle,
          ),
          element: ColumnElement(
            spacing: 12,
            crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
            children: [
              PresentationNode(
                id: "serviceHost.realmEnabled",
                element: ToggleInputElement(
                  _control(_HostInspectorFields.realmEnabled, "Host a Realm"),
                ),
              ),
              PresentationNode(
                id: "serviceHost.realmConfiguration",
                element: ConditionalElement(
                  condition: _fieldExpression(
                    _HostInspectorFields.realmEnabled,
                    const BooleanType(),
                  ),
                  whenTrue: PresentationNode(
                    id: "serviceHost.realmConfiguration.fields",
                    element: ColumnElement(
                      spacing: 12,
                      crossAxisAlignment:
                          PresentationCrossAxisAlignment.stretch,
                      children: [
                        _engineTargetSelect(
                          id: "serviceHost.realmTarget",
                          field: _HostInspectorFields.realmTarget,
                          label: "Realm target",
                          targets: realmTargets,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PresentationNode(
                id: "serviceHost.engineEnabled",
                element: ToggleInputElement(
                  _control(
                    _HostInspectorFields.engineEnabled,
                    "Run an execution engine",
                  ),
                ),
              ),
              PresentationNode(
                id: "serviceHost.engineConfiguration",
                element: ConditionalElement(
                  condition: _fieldExpression(
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
                          element: SelectInputElement(
                            control: _control(
                              _HostInspectorFields.realmAssignment,
                              "Assigned Realm",
                            ),
                            options: [
                              const SelectOption(
                                id: "hosted",
                                label: TypedExpression(
                                  resultType: StringType(),
                                  expression: LiteralExpression(
                                    StringValue("Hosted Realm"),
                                  ),
                                ),
                                value: TypedExpression(
                                  resultType: StringType(),
                                  expression: LiteralExpression(
                                    StringValue("hosted"),
                                  ),
                                ),
                              ),
                              for (final realm in realms)
                                SelectOption(
                                  id: realm.realmId.id,
                                  label: realm.realmId.id.asStringLiteral,
                                  value: realm.realmId.id.asStringLiteral,
                                ),
                            ],
                          ),
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
          element: _readOnlyInspectorValue(field),
        ),
    ],
  ),
);

PresentationElement _readOnlyInspectorValue(String field) {
  if (field == _HostInspectorFields.connected) {
    return ConditionalElement(
      condition: _fieldExpression(field, const BooleanType()),
      whenTrue: PresentationNode(
        id: "$field.connected",
        element: TextElement("Connected".asStringLiteral),
      ),
      whenFalse: PresentationNode(
        id: "$field.offline",
        element: TextElement("Offline".asStringLiteral),
      ),
    );
  }
  if (field == _HostInspectorFields.serviceRoles ||
      field == _HostInspectorFields.supportedEngines) {
    const itemBinding = BindingId(71);
    return RepeatedElement(
      source: _fieldExpression(field, _stringListType),
      itemBindingId: itemBinding,
      presentation: SequencePresentation(
        layout: PresentationSequenceLayout.children(
          PresentationChildrenLayout.column(spacing: 4),
        ),
        item: PresentationNode(
          id: "$field.item",
          element: TextElement(
            const TypedExpression(
              resultType: StringType(),
              expression: BindingExpression(
                BindingReference(bindingId: itemBinding),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return TextElement(_fieldExpression(field, const StringType()));
}

PresentationNode _engineTargetSelect({
  required String id,
  required String field,
  required String label,
  required Map<String, List<int>> targets,
}) => PresentationNode(
  id: id,
  element: SelectInputElement(
    control: _control(field, label),
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

BoundControl _control(String field, String label) =>
    BoundControl(binding: _hostField(field), label: label.asStringLiteral);

BindingReference _hostField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);

TypedExpression _fieldExpression(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(_hostField(name)),
    );
