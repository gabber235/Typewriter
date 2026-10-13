part of "services.dart";

final _serviceNameBinding = skir.ExpressionBindingId(
  value: "service.identity.name",
);
final _serviceVersionBinding = skir.ExpressionBindingId(
  value: "service.runtime.version",
);
final _serviceStateBinding = skir.ExpressionBindingId(
  value: "service.runtime.state",
);
final _serviceLastSeenBinding = skir.ExpressionBindingId(
  value: "service.runtime.last_seen",
);

final _portableTextType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _portableTimestampType = skir.TypeUse.wrapScalar(
  skir.ScalarKind.timestamp,
);
final _portableOptionalTimestampType = skir.TypeUse.createNullable(
  value: _portableTimestampType,
);

final _servicePortableCatalog = skir.EditorCatalogWireSnapshot.defaultInstance
    .asTrustedLocalCatalog();

extension ServicePortablePresentation on Service {
  BoundPresentationHost portablePresentationHost({
    required bool connected,
    required EditOwner identityOwner,
  }) => BoundPresentationHost(
    catalog: _servicePortableCatalog,
    root: () => _servicePortablePresentation(color, serviceId.id),
    budget: skir.EvaluationBudget(maxSteps: 512, maxCollectionItems: 64),
    bindings: [
      _serviceNamePresentationBinding(identityOwner),
      BoundPresentationBinding(
        id: _serviceVersionBinding,
        use: _portableTextType,
        read: (_) => skir.DataValue.wrapStringValue(role.version),
      ),
      BoundPresentationBinding(
        id: _serviceStateBinding,
        use: _portableTextType,
        read: (_) =>
            skir.DataValue.wrapStringValue(connected ? "Connected" : "Offline"),
      ),
      BoundPresentationBinding(
        id: _serviceLastSeenBinding,
        use: _portableOptionalTimestampType,
        read: (_) => lastSeen == null
            ? skir.DataValue.null_
            : skir.DataValue.wrapTimestamp(lastSeen!),
      ),
    ],
  );
}

BoundPresentationHost serviceIdentityPortablePresentationHost({
  required EditOwner identityOwner,
}) => BoundPresentationHost(
  catalog: _servicePortableCatalog,
  root: _serviceIdentityPortablePresentation,
  budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 16),
  bindings: [_serviceNamePresentationBinding(identityOwner)],
);

BoundPresentationBinding _serviceNamePresentationBinding(
  EditOwner identityOwner,
) => BoundPresentationBinding(
  id: _serviceNameBinding,
  use: _portableTextType,
  owner: identityOwner,
  control: identityOwner is EditingControlOwner
      ? (identityOwner as EditingControlOwner).bindControl()
      : null,
  read: (_) {
    final value = identityOwner.value(editorRootPath.field("name")).valueOrNull;
    return value is skir.DataValue_stringValueWrapper
        ? value
        : skir.DataValue.unfilled;
  },
  write: (path, value) {
    final target = PortableDiagnosticTarget.binding(
      skir.BindingRef(bindingId: _serviceNameBinding, path: path),
    );
    PortablePresentationWriteResult reject(String code, String message) =>
        PortablePresentationWriteResult.rejected([
          PortablePresentationDiagnostic(
            code: code,
            message: message,
            severity: skir.DiagnosticSeverity.error,
            targets: [target],
          ),
        ]);
    if (path.segments.isNotEmpty) {
      return reject("invalid_path", "The service name path is invalid");
    }
    if (value is! skir.DataValue_stringValueWrapper) {
      return reject("invalid_value", "The service name must be text");
    }
    return identityOwner
        .update(editorRootPath.field("name"), value)
        .toPortablePresentationResult(
          binding: _serviceNameBinding,
          sourcePath: editorRootPath.field("name"),
        );
  },
);

skir.PresentationNode _servicePortablePresentation(
  Color color,
  String identifier,
) => _portableColumn("service", [
  _serviceNameBinding.readExpression().resourceHeading(
    id: "service.heading",
    color: color.portableExpression,
    identifier: identifier.portableExpression,
  ),
  _inspectorSection("service.details", "Service", [
    _portableTextInput(
      "service.name",
      _serviceNameBinding,
      label: "Name",
      mappings: _serviceNameMappings,
      characterFilters: _serviceNameFilters,
    ),
    _inspectorCard("service.connection", "CONNECTION", color, [
      _inspectorConnectionStatus("service.state", _serviceStateBinding),
      _inspectorGrid("service.facts", [
        _portableFact("service.version", "Version", _serviceVersionBinding),
        _inspectorFact(
          "service.lastSeen",
          "Last seen",
          _inspectorRelativeTime(_serviceLastSeenBinding),
        ),
      ]),
    ]),
  ]),
  _portableCommit("service.save", _serviceNameBinding),
], spacing: 16);

final _serviceNameCandidate = skir.ExpressionBindingId(
  value: "presentation.service_name_completion",
);
final _serviceNameMappings =
    (skir.ValueMappings.mutable()
          ..completion = skir.ExpressionMapping(
            inputBinding: _serviceNameCandidate,
            body: skir.ExpressionNode.createCall(
              operation: skir.OperationId(value: "typewriter.regex.replace"),
              arguments: [
                skir.ExpressionNode.createCall(
                  operation: skir.OperationId(
                    value: "typewriter.regex.replace",
                  ),
                  arguments: [
                    skir.ExpressionNode.createCall(
                      operation: skir.OperationId(
                        value: "typewriter.text.lower",
                      ),
                      arguments: [
                        skir.ExpressionNode.createRead(
                          binding: _serviceNameCandidate,
                          path: editorRootPath,
                        ),
                      ],
                    ),
                    _portableLiteral(r"[\s\-]+"),
                    _portableLiteral("_"),
                  ],
                ),
                _portableLiteral("[^a-z0-9_]"),
                _portableLiteral(""),
              ],
            ),
          ))
        .toFrozen();
final _serviceNameFilters = [
  skir.CharacterFilter.wrapAllow(r"[A-Za-z0-9_\s\-]"),
];

skir.PresentationNode _serviceIdentityPortablePresentation() =>
    _portableColumn("serviceIdentity", [
      _portableTextInput(
        "serviceIdentity.name",
        _serviceNameBinding,
        label: "Name",
        mappings: _serviceNameMappings,
        characterFilters: _serviceNameFilters,
      ),
      _portableCommit("serviceIdentity.save", _serviceNameBinding),
    ]);

skir.PresentationNode _portableTextInput(
  String id,
  skir.ExpressionBindingId bindingId, {
  required String label,
  skir.ValueMappings? mappings,
  List<skir.CharacterFilter> characterFilters = const [],
}) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createTextInput(
    control: skir.BoundControl(
      binding: _portableReference(bindingId),
      label: _portableLiteral(label),
      description: null,
      prefix: null,
      semanticLabel: _portableLiteral(label),
    ),
    appearance: null,
    content: null,
    mappings: mappings,
    entry: null,
    options:
        (skir.TextEditingOptions.mutable()
              ..lines = skir.TextLines.single
              ..characterFilters = characterFilters)
            .toFrozen(),
  ),
  header: null,
);

skir.PresentationNode _portableFact(
  String id,
  String label,
  skir.ExpressionBindingId bindingId,
) => _inspectorFact(
  id,
  label,
  skir.PresentationElement.wrapText(
    _inspectorTextContent(_portableRead(bindingId)),
  ),
);

skir.PresentationNode _portableCommit(
  String id,
  skir.ExpressionBindingId bindingId,
) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createCommitControls(
    binding: _portableReference(bindingId),
  ),
  header: null,
);

skir.PresentationNode _portableColumn(
  String id,
  List<skir.PresentationNode> children, {
  double spacing = 8,
}) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: children.map(skir.AxisChild.wrapFixed),
      layout: skir.AxisChildrenLayout(
        spacing: spacing,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
  header: null,
);

skir.PresentationNode _portableText(String id, skir.ExpressionNode value) =>
    _inspectorNode(
      id,
      skir.PresentationElement.wrapText(_inspectorTextContent(value)),
    );

skir.BindingRef _portableReference(skir.ExpressionBindingId bindingId) =>
    skir.BindingRef(
      bindingId: bindingId,
      path: skir.ValuePath(segments: const []),
    );

skir.ExpressionNode _portableRead(skir.ExpressionBindingId bindingId) =>
    skir.ExpressionNode.createRead(
      binding: bindingId,
      path: skir.ValuePath(segments: const []),
    );

skir.ExpressionNode _portableLiteral(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
