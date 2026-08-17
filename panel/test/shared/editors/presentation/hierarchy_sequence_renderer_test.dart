import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

const _itemBinding = BindingId(7);
const _trunkColor = Color(0xFF967BFA);
const _firstColor = Color(0xFF4CAF50);
const _secondColor = Color(0xFF03A9F4);

void main() {
  testWidgets("flattens one item into a centered unary connection", (
    tester,
  ) async {
    await _pumpHierarchy(tester, colors: const [_firstColor]);

    final dynamic surface = _hierarchySurface(tester);
    expect(surface.debugStrokes, hasLength(1));
    final dynamic stroke = surface.debugStrokes.single;
    expect(stroke.color, _firstColor);
    expect(stroke.style.startMarker.extent, 6);
    expect(stroke.path.getBounds().width, 0);
    expect(stroke.path.getBounds().height, 12);
  });

  testWidgets("uses branching topology for one unflattened item", (
    tester,
  ) async {
    await _pumpHierarchy(
      tester,
      colors: const [_firstColor],
      flattenSingleItem: false,
    );

    final dynamic surface = _hierarchySurface(tester);
    expect(surface.debugStrokes, hasLength(2));
    expect(surface.debugStrokes.first.color, _trunkColor);
    expect(surface.debugStrokes.last.color, _firstColor);
  });

  testWidgets("routes child colored branches through the leading gutter", (
    tester,
  ) async {
    await _pumpHierarchy(tester, colors: const [_firstColor, _secondColor]);

    final dynamic surface = _hierarchySurface(tester);
    final List<dynamic> strokes = surface.debugStrokes;
    expect(strokes, hasLength(3));
    expect(strokes.map((stroke) => stroke.color), [
      _trunkColor,
      _firstColor,
      _secondColor,
    ]);
    final firstBranch = strokes[1].path.computeMetrics().single;
    final secondBranch = strokes[2].path.computeMetrics().single;
    final firstEnd = firstBranch
        .getTangentForOffset(firstBranch.length)!
        .position;
    final secondEnd = secondBranch
        .getTangentForOffset(secondBranch.length)!
        .position;
    expect(firstEnd.dy, lessThan(secondEnd.dy));
    expect(firstEnd.dx, secondEnd.dx);
  });

  testWidgets("reserves marker aware room before the first branch", (
    tester,
  ) async {
    await _pumpHierarchy(
      tester,
      colors: const [_firstColor, _secondColor],
      trunkArrowSize: 10,
      branchStartMarker: ConnectorEndpointMarker.circle(
        diameter: 6.asFloatLiteral,
      ),
    );

    final dynamic surface = _hierarchySurface(tester);
    final List<dynamic> strokes = surface.debugStrokes;
    final firstBranch = strokes[1].path.computeMetrics().single;
    final junction = firstBranch.getTangentForOffset(0.0)!.position;
    final target = firstBranch
        .getTangentForOffset(firstBranch.length)!
        .position;

    expect(junction.dy, 15);
    expect(junction.dy - 3, 12);
    expect(target.dy, 30);
  });

  testWidgets("reserves marker aware room between later items", (tester) async {
    await _pumpHierarchy(
      tester,
      colors: const [_firstColor, _secondColor],
      itemSpacing: 2,
      branchStartMarker: ConnectorEndpointMarker.circle(
        diameter: 20.asFloatLiteral,
      ),
    );

    final dynamic surface = _hierarchySurface(tester);
    final dynamic firstChild = surface.firstChild;
    final dynamic secondChild = surface.childAfter(firstChild);
    final Offset firstOffset = firstChild.parentData.offset;
    final Offset secondOffset = secondChild.parentData.offset;
    final gap = secondOffset.dy - firstOffset.dy - firstChild.size.height;
    final List<dynamic> strokes = surface.debugStrokes;
    final secondBranch = strokes[2].path.computeMetrics().single;
    final junction = secondBranch.getTangentForOffset(0.0)!.position;

    expect(gap, 24);
    expect(secondOffset.dy - junction.dy, 12);
  });

  testWidgets("mirrors hierarchy paths in right to left layouts", (
    tester,
  ) async {
    await _pumpHierarchy(tester, colors: const [_firstColor, _secondColor]);
    final dynamic leftSurface = _hierarchySurface(tester);
    final leftBounds = [
      for (final dynamic stroke in leftSurface.debugStrokes)
        stroke.path.getBounds() as Rect,
    ];

    await _pumpHierarchy(
      tester,
      colors: const [_firstColor, _secondColor],
      textDirection: TextDirection.rtl,
    );
    final dynamic rightSurface = _hierarchySurface(tester);
    final width = rightSurface.size.width as double;
    final rightBounds = [
      for (final dynamic stroke in rightSurface.debugStrokes)
        stroke.path.getBounds() as Rect,
    ];

    for (var index = 0; index < leftBounds.length; index++) {
      expect(
        leftBounds[index].left,
        closeTo(width - rightBounds[index].right, 0.01),
      );
      expect(
        leftBounds[index].right,
        closeTo(width - rightBounds[index].left, 0.01),
      );
    }
  });

  testWidgets("diagnoses an anchor offset beyond the child width", (
    tester,
  ) async {
    await _pumpHierarchy(
      tester,
      colors: const [_firstColor],
      itemAnchor: ConnectorAnchor.offset(500.asFloatLiteral),
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
    );
    await tester.pump();

    final dynamic surface = _hierarchySurface(tester);
    expect(surface.debugStrokes, isEmpty);
    expect(surface.debugDiagnostics, hasLength(1));
    expect(find.textContaining("anchor offset exceeds"), findsOneWidget);
  });
}

Future<void> _pumpHierarchy(
  WidgetTester tester, {
  required List<Color> colors,
  bool flattenSingleItem = true,
  ConnectorAnchor itemAnchor = const ConnectorAnchor.center(),
  PresentationCrossAxisAlignment crossAxisAlignment =
      PresentationCrossAxisAlignment.stretch,
  TextDirection textDirection = TextDirection.ltr,
  double trunkArrowSize = 6,
  ConnectorEndpointMarker? branchStartMarker,
  double itemSpacing = 10,
}) async {
  await tester.pumpTestApp(
    child: Directionality(
      textDirection: textDirection,
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "repeated",
            element: RepeatedElement(
              source: _colorList(colors),
              itemBindingId: _itemBinding,
              presentation: SequencePresentation(
                item: PresentationNode(
                  id: "item",
                  element: ContainerElement(
                    child: PresentationNode(
                      id: "item.padding",
                      element: PaddingElement(
                        top: 8,
                        bottom: 8,
                        child: PresentationNode(
                          id: "item.label",
                          element: TextElement("Item".asStringLiteral),
                        ),
                      ),
                    ),
                  ),
                ),
                layout: PresentationSequenceLayout.hierarchy(
                  HierarchySequenceLayout(
                    unaryConnector: _style(
                      _itemColor(),
                      startMarker: ConnectorEndpointMarker.arrow(
                        size: 6.asFloatLiteral,
                      ),
                    ),
                    trunkConnector: _style(
                      _color(_trunkColor),
                      cornerRadius: 8,
                      startMarker: ConnectorEndpointMarker.arrow(
                        size: trunkArrowSize.asFloatLiteral,
                      ),
                    ),
                    branchConnector: _style(
                      _itemColor(),
                      cornerRadius: 8,
                      startMarker: branchStartMarker,
                    ),
                    itemSpacing: itemSpacing.asFloatLiteral,
                    indentation: 20.asFloatLiteral,
                    leadingSpacing: 12.asFloatLiteral,
                    itemAnchor: itemAnchor,
                    flattenSingleItem: flattenSingleItem.asBooleanLiteral,
                    crossAxisAlignment: crossAxisAlignment,
                  ),
                ),
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

dynamic _hierarchySurface(WidgetTester tester) {
  final surface = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
  );
  return tester.renderObject(surface);
}

ConnectorStyle _style(
  TypedExpression color, {
  double cornerRadius = 0,
  ConnectorEndpointMarker? startMarker,
}) => ConnectorStyle(
  stroke: ConnectorStroke(color: color, width: 2.asFloatLiteral),
  cornerRadius: cornerRadius.asFloatLiteral,
  startMarker: startMarker,
);

TypedExpression _colorList(List<Color> colors) => TypedExpression(
  resultType: ListType(element: NamedType(standardTypeRefs.color)),
  expression: LiteralExpression(
    ListValue([
      for (final color in colors) IntegerValue(BigInt.from(color.toARGB32())),
    ]),
  ),
);

TypedExpression _itemColor() => TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: BindingExpression(BindingReference(bindingId: _itemBinding)),
);

TypedExpression _color(Color color) => TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: LiteralExpression(IntegerValue(BigInt.from(color.toARGB32()))),
);

EditorProtocolRenderer _renderer(PresentationNode presentation) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "HierarchyRoot"),
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
