import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final accepts in [false, true]) {
    testWidgets(
      "a target that ${accepts ? "accepts" : "refuses"} a drop keeps the "
      "graph from moving the node",
      (tester) async {
        var moves = 0;
        var drops = 0;
        final panel = await tester.pumpGraph(
          Graph(
            data: GraphData(
              cellSize: 50,
              elements: [
                graphNode(
                  "Source",
                  x: 0,
                  body: const DraggableGraphNode("Source"),
                ),
                graphNode(
                  "Target",
                  x: 4,
                  body: GraphDragTargetRegion(
                    targetId: const GraphIdentifier("Target"),
                    child: DragTarget<GraphDragPayload<GraphDragData>>(
                      onWillAcceptWithDetails: (details) =>
                          accepts && details.data.canHover,
                      onAcceptWithDetails: (details) {
                        if (details.data.claim()) drops++;
                      },
                      builder: (_, _, rejected) => GraphNode(
                        rejected.isEmpty ? "Target" : "Refuses drop",
                      ),
                    ),
                  ),
                ),
              ],
              edges: const [],
            ),
            onElementsMoved: (_) => moves++,
          ),
        );
        final target = panel.graph.rectOf("Target").center;

        final gesture = await panel.graph.grab("Source");
        await gesture.moveTo(target);
        await tester.pump();
        expect(panel.graph.hasNode("Refuses drop"), !accepts);
        await gesture.up();
        await panel.settle();

        expect(moves, 0);
        expect(drops, accepts ? 1 : 0);
      },
    );
  }

  testWidgets("a node that is its own drop region still moves on the graph", (
    tester,
  ) async {
    final (:panel, :moves, resizes: _) = await tester.pumpCommittingGraph([
      graphNode(
        "Source",
        x: 0,
        body: DraggableGraphNode(
          "Source",
          child: GraphDragTargetRegion(
            targetId: const GraphIdentifier("Source"),
            // Refuses every drop, so the node is only its own region.
            child: DragTarget<GraphDragPayload<GraphDragData>>(
              onWillAcceptWithDetails: (_) => false,
              builder: (_, _, _) => const GraphNode("Source"),
            ),
          ),
        ),
      ),
    ]);

    await panel.graph.drag("Source", const Offset(30, 0));

    expect(moves, hasLength(1));
    expect(moves.single.single.x, 1);
  });
}
