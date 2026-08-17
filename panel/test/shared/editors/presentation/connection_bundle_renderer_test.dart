import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("spans targets on both sides with bounded branch rounding", (
    tester,
  ) async {
    await _pumpBundle(tester, [
      _nestedTarget("above"),
      _localSource(),
      _nestedTarget("below"),
    ]);

    final dynamic resolution = _outerResolution(tester);
    expect(resolution.strokes, hasLength(3));
    final Path trunk = resolution.strokes.first.path;
    final trunkBounds = trunk.getBounds();
    final trunkMetrics = trunk.computeMetrics().toList(growable: false);
    expect(trunkMetrics, hasLength(2));
    final source = trunkMetrics.first.getTangentForOffset(0)!.position;
    final junction = trunkMetrics.last.getTangentForOffset(0)!.position;
    final primaryJunction = trunkMetrics.first
        .getTangentForOffset((junction - source).distance)!
        .position;
    expect((primaryJunction - junction).distance, lessThan(0.01));
    for (final dynamic stroke in resolution.strokes.skip(1)) {
      final metric = (stroke.path as Path).computeMetrics().single;
      final start = metric.getTangentForOffset(0)!.position;
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect(start.dy, inInclusiveRange(trunkBounds.top, trunkBounds.bottom));
      expect(
        start.dy,
        inInclusiveRange(
          math.min(source.dy, end.dy),
          math.max(source.dy, end.dy),
        ),
      );
    }
  });

  testWidgets("keeps one rounded trunk contour for same side targets", (
    tester,
  ) async {
    await _pumpBundle(tester, [
      _localSource(),
      _nestedTarget("first"),
      _nestedTarget("second"),
    ]);

    final dynamic resolution = _outerResolution(tester);
    final Path trunk = resolution.strokes.first.path;
    final metrics = trunk.computeMetrics().toList(growable: false);
    expect(metrics, hasLength(1));
    final metric = metrics.single;
    final start = metric.getTangentForOffset(0)!.position;
    final end = metric.getTangentForOffset(metric.length)!.position;
    final manhattanLength =
        (end.dx - start.dx).abs() + (end.dy - start.dy).abs();
    expect(metric.length, lessThan(manhattanLength));
  });
}

Future<void> _pumpBundle(
  WidgetTester tester,
  List<PresentationNode> children,
) async {
  await tester.pumpTestApp(
    child: SizedBox(
      width: 240,
      child: _renderer(
        PresentationNode(
          id: "layer",
          element: ConnectionLayerElement(
            connections: [
              PresentationConnection.bundle(
                source: const PresentationAnchorSelector.local("source"),
                targets: const PresentationAnchorSelector.exportedGroup(
                  "targets",
                ),
                path: ConnectionBundlePath.orthogonal(
                  OrthogonalConnectionBundlePath(
                    axis: ConnectionAxis.vertical,
                    bendPosition: 0.5.asFloatLiteral,
                  ),
                ),
                trunkStyle: _style(8),
                branchStyle: _style(200),
              ),
            ],
            child: PresentationNode(
              id: "content",
              element: ColumnElement(
                spacing: 40,
                crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

PresentationNode _nestedTarget(String id) => PresentationNode(
  id: "$id.layer",
  element: ConnectionLayerElement(
    connections: [_inactiveConnection()],
    child: PresentationNode(
      id: "$id.anchor",
      element: PresentationAnchorElement(
        anchors: const [
          PresentationAnchorPoint(
            id: "target",
            groupIds: ["targets"],
            alignment: PresentationAnchorAlignment.centerEnd,
            exportToParent: true,
          ),
        ],
        child: PresentationNode(
          id: "$id.label",
          element: TextElement(id.asStringLiteral),
        ),
      ),
    ),
  ),
);

PresentationNode _localSource() => PresentationNode(
  id: "source.anchor",
  element: PresentationAnchorElement(
    anchors: const [
      PresentationAnchorPoint(
        id: "source",
        alignment: PresentationAnchorAlignment.center,
      ),
    ],
    child: PresentationNode(
      id: "source.label",
      element: TextElement("source".asStringLiteral),
    ),
  ),
);

PresentationConnection _inactiveConnection() =>
    PresentationConnection.connection(
      source: const PresentationAnchorSelector.local("unused.source"),
      target: const PresentationAnchorSelector.local("unused.target"),
      path: const ConnectionPath.straight(),
      style: _style(0),
      visibleIf: false.asBooleanLiteral,
    );

ConnectorStyle _style(double radius) => ConnectorStyle(
  stroke: ConnectorStroke(
    color: TypedExpression(
      resultType: NamedType(standardTypeRefs.color),
      expression: LiteralExpression(IntegerValue(BigInt.from(0xFF967BFA))),
    ),
    width: 2.asFloatLiteral,
  ),
  cornerRadius: radius.asFloatLiteral,
);

dynamic _outerResolution(WidgetTester tester) {
  final surfaces = find.byWidgetPredicate(
    (widget) =>
        widget.runtimeType.toString() == "_ConnectionLayerRenderSurface",
  );
  final dynamic renderObject = tester.renderObject(surfaces.first);
  return renderObject.debugResolution;
}

EditorProtocolRenderer _renderer(PresentationNode presentation) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "BundleRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: const TypedValueEnvelope(rootType: root, rootValue: UnitValue()),
    typeCatalog: const TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: UnitType(),
      ),
    ]),
    presentation: presentation,
  );
}
