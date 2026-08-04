import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

GraphElement _element(
  String id, {
  required int x,
  required int y,
  int width = 1,
  int height = 1,
  int priority = 0,
}) {
  return GraphElement(
    id: GraphIdentifier(id),
    x: x,
    y: y,
    width: width,
    height: height,
    priority: priority,
    builder: (_) => const SizedBox(),
  );
}

void main() {
  group("GraphLayoutEngine", () {
    test("places move and resize previews", () {
      final data = GraphData(
        cellSize: 10,
        elements: [
          _element("moving", x: 1, y: 2, width: 2, height: 3),
          _element("resizing", x: 5, y: 6, width: 1, height: 1),
        ],
        edges: const [],
      );

      final layout = const GraphLayoutEngine().build(
        data: data,
        preview: GraphInteractionPreview(
          movingIds: {const GraphIdentifier("moving")},
          moveDelta: (2, -1),
          resize: const GraphResizePreview(
            id: GraphIdentifier("resizing"),
            width: 4,
            height: 2,
          ),
        ),
      );

      expect(
        layout.placementsById[const GraphIdentifier("moving")]!.bounds,
        const Rect.fromLTWH(30, 10, 20, 30),
      );
      expect(
        layout.placementsById[const GraphIdentifier("resizing")]!.bounds,
        const Rect.fromLTWH(50, 60, 40, 20),
      );
    });

    test("culls elements at viewport boundaries", () {
      final data = GraphData(
        cellSize: 10,
        elements: [
          _element("inside", x: 1, y: 1),
          _element("partial", x: 9, y: 9, width: 2, height: 2),
          _element("touching", x: 10, y: 2),
          _element("outside", x: 12, y: 12),
        ],
        edges: const [],
      );
      final layout = const GraphLayoutEngine().build(data: data);

      final visible = layout
          .visibleElements(const Rect.fromLTWH(0, 0, 100, 100))
          .map((placed) => placed.id.id)
          .toSet();

      expect(visible, {"inside", "partial"});
    });

    test("keeps elements inside viewport overscan", () {
      final data = GraphData(
        cellSize: 10,
        elements: [_element("near", x: 11, y: 2), _element("far", x: 31, y: 2)],
        edges: const [],
      );
      final layout = const GraphLayoutEngine().build(data: data);

      final visible = layout
          .visibleElements(const Rect.fromLTWH(0, 0, 100, 100), overscan: 100)
          .map((placed) => placed.id.id)
          .toSet();

      expect(visible, {"near"});
    });

    test("retains requested elements outside viewport culling", () {
      final data = GraphData(
        cellSize: 10,
        elements: [_element("focused", x: 100, y: 100)],
        edges: const [],
      );
      final layout = const GraphLayoutEngine().build(data: data);

      final visible = layout
          .visibleElements(
            const Rect.fromLTWH(0, 0, 100, 100),
            retainedIds: const {"focused"},
          )
          .map((placed) => placed.id.id);

      expect(visible, ["focused"]);
    });

    test("orders by priority and computes an area weighted center", () {
      final data = GraphData(
        cellSize: 10,
        elements: [
          _element("high", x: 10, y: 0, priority: 2),
          _element("large", x: 0, y: 0, width: 4, height: 4, priority: 0),
          _element("middle", x: 5, y: 0, priority: 1),
        ],
        edges: const [],
      );
      final layout = const GraphLayoutEngine().build(data: data);

      expect(layout.paintOrder.map((placed) => placed.id.id), [
        "large",
        "middle",
        "high",
      ]);
      expect(layout.centerOfMass.dx, lessThan(55));
    });

    test("resolves every edge connection side from current data", () {
      final source = _element("source", x: 0, y: 0, width: 2, height: 2);
      final target = _element("target", x: 4, y: 4, width: 2, height: 2);
      final expected = {
        EdgeSide.top: const Offset(10, 0),
        EdgeSide.bottom: const Offset(10, 20),
        EdgeSide.left: const Offset(0, 10),
        EdgeSide.right: const Offset(20, 10),
      };

      for (final side in EdgeSide.values) {
        final data = GraphData(
          cellSize: 10,
          elements: [source, target],
          edges: [
            GraphEdge(
              id: "edge",
              source: source.id,
              target: target.id,
              color: Colors.red,
              sourceSide: side,
              targetSide: side,
            ),
          ],
        );
        final edge = const GraphLayoutEngine().build(data: data).edgesFor([
          source.id,
        ]).single;

        expect(edge.sourcePoint, expected[side]);
        expect(edge.targetPoint, expected[side]! + const Offset(40, 40));
      }
    });

    test("replaces and removes edges without retaining stale state", () {
      final elements = [
        _element("source", x: 0, y: 0),
        _element("target", x: 2, y: 0),
      ];
      GraphLayoutResult build(List<GraphEdge> edges) {
        return const GraphLayoutEngine().build(
          data: GraphData(cellSize: 10, elements: elements, edges: edges),
        );
      }

      final initial = build([
        const GraphEdge(
          id: "edge",
          source: GraphIdentifier("source"),
          target: GraphIdentifier("target"),
          color: Colors.red,
        ),
      ]);
      final replaced = build([
        const GraphEdge(
          id: "edge",
          source: GraphIdentifier("source"),
          target: GraphIdentifier("target"),
          color: Colors.blue,
          sourceSide: EdgeSide.bottom,
          targetSide: EdgeSide.top,
        ),
      ]);
      final removed = build(const []);

      expect(
        initial
            .edgesFor(elements.map((element) => element.id))
            .single
            .edge
            .color,
        Colors.red,
      );
      expect(
        replaced
            .edgesFor(elements.map((element) => element.id))
            .single
            .edge
            .color,
        Colors.blue,
      );
      expect(removed.edgesFor(elements.map((element) => element.id)), isEmpty);
    });
  });
}
