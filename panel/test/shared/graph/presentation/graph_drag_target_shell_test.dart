import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the graph previews a drag anywhere in its viewport", (
    tester,
  ) async {
    var commits = 0;
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [
            graphNode("A", x: 1, y: 1, body: const DraggableGraphNode("A")),
          ],
          edges: const [],
        ),
        onElementsMoved: (_) => commits++,
      ),
    );

    final gesture = await panel.graph.grab("A");
    await gesture.moveBy(const Offset(160, 120));
    await tester.pump();

    expect(panel.shows("Dragging A"), isFalse);

    await gesture.up();
    await panel.settle();

    expect(commits, 1);
  });

  testWidgets("a graph node still takes a tap while dragging is enabled", (
    tester,
  ) async {
    final focusNode = FocusNode(debugLabel: "Tap");
    addTearDown(focusNode.dispose);
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [
            graphElement(
              "Tap",
              x: 2,
              y: 2,
              width: 3,
              height: 2,
              body: GestureDetector(
                onTap: focusNode.requestFocus,
                child: GraphNode("Tap", focusNode: focusNode),
              ),
            ),
          ],
          edges: const [],
        ),
        onElementsMoved: (_) {},
      ),
    );
    expect(focusNode.hasFocus, isFalse);

    await panel.tapOn(panel.labeled("Tap"));

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets("a graph without a move handler leaves a dragged node alone", (
    tester,
  ) async {
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [
            graphNode("X", x: 1, y: 1, body: const DraggableGraphNode("X")),
          ],
          edges: const [],
        ),
      ),
    );
    final before = panel.graph.rectOf("X");

    final gesture = await panel.graph.grab("X");
    await gesture.moveBy(const Offset(120, 60));
    await tester.pump();

    expect(panel.graph.rectOf("X"), before);

    await gesture.up();
    await panel.settle();
    expect(panel.graph.rectOf("X"), before);
  });
}
