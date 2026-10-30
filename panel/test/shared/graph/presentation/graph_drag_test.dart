import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _cell = 50.0;

void main() {
  testWidgets("dropping a node commits its snapped grid position", (
    tester,
  ) async {
    final moves = <List<GraphMoveCommitPayload>>[];
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: _cell,
          elements: [
            graphNode("A", x: 2, y: 3, body: const DraggableGraphNode("A")),
          ],
          edges: const [],
        ),
        onElementsMoved: moves.add,
      ),
    );

    await panel.graph.drag("A", const Offset(_cell * 1, _cell * 2));

    expect(moves, hasLength(1));
    expect(moves.single.single.id, const GraphIdentifier("A"));
    expect((moves.single.single.x, moves.single.single.y), (3, 5));
  });

  for (final (distance, cells) in [(24.0, 0), (25.0, 1)]) {
    testWidgets("a drag of $distance pixels rounds to $cells cells", (
      tester,
    ) async {
      final moves = <List<GraphMoveCommitPayload>>[];
      final panel = await tester.pumpGraph(
        Graph(
          data: GraphData(
            cellSize: _cell,
            elements: [
              graphNode("Snap", body: const DraggableGraphNode("Snap")),
            ],
            edges: const [],
          ),
          onElementsMoved: moves.add,
        ),
      );

      await panel.graph.drag(
        "Snap",
        Offset(distance, 0),
        at: const Offset(1, 1),
      );

      expect(moves, hasLength(1));
      expect((moves.single.single.x, moves.single.single.y), (cells, 0));
    });
  }

  testWidgets("dragging a container moves elements fully inside it", (
    tester,
  ) async {
    final moves = <List<GraphMoveCommitPayload>>[];
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: _cell,
          elements: [
            graphNode(
              "Parent",
              x: 1,
              y: 1,
              cells: 4,
              body: const DraggableGraphNode("Parent"),
            ),
            graphNode(
              "Child",
              x: 2,
              y: 2,
              cells: 1,
              body: const DraggableGraphNode("Child"),
            ),
          ],
          edges: const [],
        ),
        onElementsMoved: moves.add,
      ),
    );

    await panel.graph.drag(
      "Parent",
      const Offset(_cell * 2, _cell * 1),
      at: const Offset(_cell * 3.5, _cell * 3.5),
    );

    expect(moves, hasLength(1));
    expect(
      {for (final move in moves.single) move.id.id: (move.x, move.y)},
      {"Parent": (3, 2), "Child": (4, 3)},
    );
  });

  testWidgets("dropping an element the graph does not know commits nothing", (
    tester,
  ) async {
    final moves = <List<GraphMoveCommitPayload>>[];
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: _cell,
          elements: [
            graphNode(
              "Stranger",
              body: const DraggableGraphNode("Stranger", id: "unknown"),
            ),
          ],
          edges: const [],
        ),
        onElementsMoved: moves.add,
      ),
    );

    await panel.graph.drag("Stranger", const Offset(80, 40));

    expect(moves, isEmpty);
  });
}
