import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("connection layers report unresolved declared anchors", (
    tester,
  ) async {
    await tester.showComponent(
      Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "connection.layer",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.createConnectionLayer(
                child: skir.PresentationNode(
                  nodeId: "connection.content",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: skir.PresentationElement.wrapDivider(
                    skir.DividerAppearance.defaultInstance,
                  ),
                  header: null,
                ),
                connections: [
                  skir.PresentationConnection.createConnection(
                    source: skir.PresentationAnchorSelector.wrapLocal("source"),
                    target: skir.PresentationAnchorSelector.wrapLocal("target"),
                    path: skir.ConnectionPath.straight,
                    style: skir.ConnectorStyle(
                      stroke: skir.ConnectorStroke(
                        color: skir.PresentationColor.wrapValue(
                          skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapInteger("4278190335"),
                          ),
                        ),
                        width: skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapInteger("2"),
                        ),
                      ),
                      cornerRadius: skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapInteger("0"),
                      ),
                      startMarker: null,
                      endMarker: null,
                    ),
                    markers: const [],
                    visibleIf: null,
                  ),
                ],
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              operations: testPortableOperations(),
              bindings: const {},
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining("Connection source anchor is missing"),
      findsOneWidget,
    );
  });
}
