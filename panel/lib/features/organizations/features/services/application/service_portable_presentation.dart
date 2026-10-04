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
  EditorSourcePresentationHost portablePresentationHost({
    required bool connected,
    required EditOwner identityOwner,
  }) => EditorSourcePresentationHost(
    catalog: _servicePortableCatalog,
    root: _servicePortablePresentation,
    budget: skir.EvaluationBudget(maxSteps: 512, maxCollectionItems: 64),
    capabilities: identityOwner.portablePresentationCapabilities,
    bindings: [
      _serviceNamePresentationBinding(identityOwner),
      EditorSourcePresentationBinding(
        id: _serviceVersionBinding,
        use: _portableTextType,
        read: (_) => skir.DataValue.wrapStringValue(role.version),
      ),
      EditorSourcePresentationBinding(
        id: _serviceStateBinding,
        use: _portableTextType,
        read: (_) =>
            skir.DataValue.wrapStringValue(connected ? "Connected" : "Offline"),
      ),
      EditorSourcePresentationBinding(
        id: _serviceLastSeenBinding,
        use: _portableTextType,
        read: (_) {
          final value = lastSeen;
          return skir.DataValue.wrapStringValue(
            value?.toIso8601String() ?? "Never",
          );
        },
      ),
    ],
  );
}

EditorSourcePresentationHost serviceIdentityPortablePresentationHost({
  required EditOwner identityOwner,
  required Future<void> Function() commit,
}) => EditorSourcePresentationHost(
  catalog: _servicePortableCatalog,
  root: _serviceIdentityPortablePresentation,
  budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 16),
  capabilities: PortablePresentationCapabilities(commit: commit),
  bindings: [_serviceNamePresentationBinding(identityOwner)],
);

EditorSourcePresentationBinding _serviceNamePresentationBinding(
  EditOwner identityOwner,
) => EditorSourcePresentationBinding(
  id: _serviceNameBinding,
  use: _portableTextType,
  owner: identityOwner,
  read: (_) =>
      switch (identityOwner.value(DataPath.root.field("name")).valueOrNull) {
        StringValue(:final value) => skir.DataValue.wrapStringValue(value),
        _ => skir.DataValue.unfilled,
      },
  write: (path, value) {
    if (path.segments.isNotEmpty) {
      return const PortablePresentationWriteResult.rejected(
        "The service name path is invalid",
      );
    }
    if (value case skir.DataValue_stringValueWrapper(:final value)) {
      return identityOwner
          .update(DataPath.root.field("name"), StringValue(value))
          .portablePresentationResult;
    }
    return const PortablePresentationWriteResult.rejected(
      "The service name must be text",
    );
  },
);

extension EditOwnerPortablePresentation on EditOwner {
  PortablePresentationCapabilities get portablePresentationCapabilities =>
      PortablePresentationCapabilities(
        commit: this is EditorSource
            ? () async {
                await (this as EditorSource).flush();
              }
            : null,
      );
}

extension EditorMutationPortablePresentation on EditorMutationResult {
  PortablePresentationWriteResult get portablePresentationResult =>
      switch (this) {
        AppliedEditorMutation() =>
          const PortablePresentationWriteResult.applied(),
        ConflictingEditorMutation() =>
          const PortablePresentationWriteResult.rejected(
            "The service changed while it was being edited",
          ),
        InvalidEditorMutation() =>
          const PortablePresentationWriteResult.rejected(
            "The service name is invalid",
          ),
      };
}

skir.PresentationNode _servicePortablePresentation() =>
    _portableColumn("service", [
      _portableTextInput(
        "service.name",
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
      _portableFact("service.state", "Connection", _serviceStateBinding),
      _portableFact("service.version", "Version", _serviceVersionBinding),
      _portableFact("service.last_seen", "Last seen", _serviceLastSeenBinding),
      _portableCommit("service.save", _serviceNameBinding),
    ]);

skir.PresentationNode _serviceIdentityPortablePresentation() =>
    _portableColumn("serviceIdentity", [
      _portableTextInput(
        "serviceIdentity.name",
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
      _portableCommit("serviceIdentity.save", _serviceNameBinding),
    ]);

skir.PresentationNode _portableTextInput(
  String id,
  skir.ExpressionBindingId bindingId, {
  required String label,
  List<skir.TextInputFormat> inputFormatters = const [],
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
    multiline: false,
    placeholder: null,
    inputFormatters: inputFormatters,
  ),
  header: null,
);

skir.PresentationNode _portableFact(
  String id,
  String label,
  skir.ExpressionBindingId bindingId,
) => _portableColumn(id, [
  _portableText("$id.label", _portableLiteral(label)),
  _portableText("$id.value", _portableRead(bindingId)),
]);

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
  List<skir.PresentationNode> children,
) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: children.map(skir.AxisChild.wrapFixed),
      layout: skir.AxisChildrenLayout(
        spacing: 8,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
  header: null,
);

skir.PresentationNode _portableText(String id, skir.ExpressionNode value) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createText(
        value: value,
        color: null,
        fontSize: null,
        fontWeight: null,
        fontItalic: null,
        fontOpticalSize: null,
        fontSlant: null,
        fontWidth: null,
        textAlignment: null,
        lineHeight: null,
        letterSpacing: null,
        decoration: null,
        semanticLabel: null,
        paragraph: skir.TextParagraph.defaultInstance,
      ),
      header: null,
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
