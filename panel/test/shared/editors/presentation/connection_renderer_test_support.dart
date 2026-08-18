part of "connection_renderer_test.dart";

PresentationConnection _bundleConnection() => PresentationConnection.bundle(
  source: const PresentationAnchorSelector.local("source"),
  targets: const PresentationAnchorSelector.exportedGroup("targets"),
  path: const ConnectionBundlePath.fan(),
  trunkStyle: _connectorStyle(_colorExpression(const Color(0xFF967BFA)), 2),
  branchStyle: _connectorStyle(_colorExpression(const Color(0xFF4CAF50)), 3),
);

PresentationConnection _inactiveConnection() =>
    PresentationConnection.connection(
      source: const PresentationAnchorSelector.local("inactive.source"),
      target: const PresentationAnchorSelector.local("inactive.target"),
      path: const ConnectionPath.straight(),
      style: _connectorStyle(_colorExpression(const Color(0xFF967BFA)), 1),
      visibleIf: false.asBooleanLiteral,
    );

PresentationNode _curvedConnectionPresentation() => PresentationNode(
  id: "curve.layer",
  element: ConnectionLayerElement(
    connections: [
      PresentationConnection.connection(
        source: const PresentationAnchorSelector.local("source"),
        target: const PresentationAnchorSelector.local("target"),
        path: ConnectionPath.curved(
          CurvedConnectionPath(
            sourceControlOffset: PresentationOffset(
              x: 60.asFloatLiteral,
              y: 20.asFloatLiteral,
            ),
            targetControlOffset: PresentationOffset(
              x: 60.asFloatLiteral,
              y: (-20).asFloatLiteral,
            ),
          ),
        ),
        style: _connectorStyle(_colorExpression(const Color(0xFF967BFA)), 2),
        markers: [
          ConnectionMarker(
            node: PresentationNode(
              id: "curve.marker",
              element: TextElement("Curve marker".asStringLiteral),
            ),
            position: 0.5.asFloatLiteral,
            alignToPath: true.asBooleanLiteral,
          ),
        ],
      ),
    ],
    child: PresentationNode(
      id: "curve.anchors",
      element: ColumnElement(
        spacing: 80,
        crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
        children: [
          _anchor("source", PresentationAnchorAlignment.bottomStart),
          _anchor("target", PresentationAnchorAlignment.topStart),
        ],
      ),
    ),
  ),
);

dynamic _connectionResolution(WidgetTester tester) {
  final surfaces = find.byWidgetPredicate(
    (widget) =>
        widget.runtimeType.toString() == "_ConnectionLayerRenderSurface",
  );
  final dynamic renderObject = tester.renderObject(surfaces.first);
  return renderObject.debugResolution;
}

PresentationNode _exportedAnchor([String id = "target"]) => PresentationNode(
  id: "$id.node",
  element: PresentationAnchorElement(
    anchors: const [
      PresentationAnchorPoint(
        id: "target",
        groupIds: ["targets"],
        alignment: PresentationAnchorAlignment.topCenter,
        exportToParent: true,
      ),
    ],
    child: PresentationNode(
      id: "$id.content",
      element: TextElement(id.asStringLiteral),
    ),
  ),
);

PresentationNode _anchor(String id, PresentationAnchorAlignment alignment) =>
    PresentationNode(
      id: "$id.node",
      element: PresentationAnchorElement(
        anchors: [PresentationAnchorPoint(id: id, alignment: alignment)],
        child: PresentationNode(
          id: "$id.content",
          element: TextElement(id.asStringLiteral),
        ),
      ),
    );

ConnectorStyle _connectorStyle(
  TypedExpression color,
  double width, {
  double cornerRadius = 0,
  ConnectorEndpointMarker? startMarker,
  ConnectorEndpointMarker? endMarker,
}) => ConnectorStyle(
  stroke: ConnectorStroke(color: color, width: width.asFloatLiteral),
  cornerRadius: cornerRadius.asFloatLiteral,
  startMarker: startMarker,
  endMarker: endMarker,
);

TypedExpression _colorExpression(Color color) => TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: LiteralExpression(IntegerValue(BigInt.from(color.toARGB32()))),
);

TypedExpression _bindingColorExpression(BindingId bindingId) => TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: BindingExpression(BindingReference(bindingId: bindingId)),
);

EditorProtocolRenderer _renderer(
  PresentationNode presentation, {
  DataValue rootValue = const UnitValue(),
  TypeExpression rootRepresentation = const UnitType(),
}) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "ConnectionRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: rootValue),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: rootRepresentation,
      ),
    ]),
    presentation: presentation,
  );
}
