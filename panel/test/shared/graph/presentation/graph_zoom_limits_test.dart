import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final (direction, step, spread, limit) in [
    ("in", 8.0, 160.0, Graph.kGraphMaxScale),
    ("out", -8.0, 440.0, Graph.kGraphMinScale),
  ]) {
    testWidgets("pinching $direction stops at scale $limit", (tester) async {
      // A node of two cells, 100 pixels wide at scale 1.
      final panel = await tester.pumpGraph(
        Graph(
          data: GraphData(
            cellSize: 50,
            elements: [graphNode("Node")],
            edges: const [],
          ),
        ),
      );
      // The node's width as a share of its width at scale 1.
      double scale() => panel.graph.rectOf("Node").width / 100;
      expect(scale(), closeTo(1, 1e-6));

      await panel.graph.pinch(
        spread: spread,
        step: step,
        done: () => (scale() - limit).abs() < 1e-3,
      );
      await panel.graph.pinch(spread: spread, step: step, steps: 10);

      expect(scale(), closeTo(limit, 1e-6));
    });
  }
}
