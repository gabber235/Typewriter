import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("GraphData validation", () {
    for (final cellSize in [0.0, -1.0, double.infinity, double.nan]) {
      test("rejects cell size $cellSize", () {
        expect(
          () => GraphData(cellSize: cellSize, elements: [], edges: []),
          throwsArgumentError,
        );
      });
    }

    test("rejects nonpositive dimensions", () {
      expect(
        () => GraphData(
          cellSize: 10,
          elements: [graphElement("a", width: 0)],
          edges: [],
        ),
        throwsArgumentError,
      );
      expect(
        () => GraphData(
          cellSize: 10,
          elements: [graphElement("a", height: -1)],
          edges: [],
        ),
        throwsArgumentError,
      );
    });

    test("rejects blank and duplicate identifiers", () {
      expect(
        () => GraphData(cellSize: 10, elements: [graphElement(" ")], edges: []),
        throwsArgumentError,
      );
      expect(
        () => GraphData(
          cellSize: 10,
          elements: [graphElement("a"), graphElement("a")],
          edges: [],
        ),
        throwsArgumentError,
      );
      expect(
        () => GraphData(
          cellSize: 10,
          elements: [graphElement("a")],
          edges: const [
            GraphEdge(
              id: "edge",
              source: GraphIdentifier("a"),
              target: GraphIdentifier("missing"),
              color: Colors.red,
            ),
            GraphEdge(
              id: "edge",
              source: GraphIdentifier("a"),
              target: GraphIdentifier("missing"),
              color: Colors.blue,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("owns immutable snapshots", () {
      final elements = [graphElement("a")];
      final edges = [
        const GraphEdge(
          id: "edge",
          source: GraphIdentifier("a"),
          target: GraphIdentifier("missing"),
          color: Colors.red,
        ),
      ];
      final data = GraphData(cellSize: 10, elements: elements, edges: edges);

      elements.clear();
      edges.clear();

      expect(data.elements, hasLength(1));
      expect(data.edges, hasLength(1));
      expect(
        () => data.elements.add(graphElement("b")),
        throwsUnsupportedError,
      );
      expect(data.keyedElements.clear, throwsUnsupportedError);
      expect(
        () => data.elementsConnectedEdges[const GraphIdentifier("a")]!.clear(),
        throwsUnsupportedError,
      );
    });

    test("allows negative coordinates and missing edge endpoints", () {
      final data = GraphData(
        cellSize: 10,
        elements: [graphElement("a", x: -2, y: -3)],
        edges: const [
          GraphEdge(
            id: "edge",
            source: GraphIdentifier("a"),
            target: GraphIdentifier("missing"),
            color: Colors.red,
          ),
        ],
      );

      final layout = const GraphLayoutEngine().build(data: data);

      expect(
        layout.placementsById[const GraphIdentifier("a")]!.bounds.topLeft,
        const Offset(-20, -30),
      );
      expect(layout.edgesFor([const GraphIdentifier("a")]), isEmpty);
    });
  });
}
