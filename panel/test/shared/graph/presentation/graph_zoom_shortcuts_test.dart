import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("equal zooms in", (tester) async {
    final focus = testFocusNode("Node");
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [graphNode("Node", focusNode: focus)],
          edges: const [],
        ),
      ),
    );
    await panel.requestFocus(focus);
    expect(panel.graph.rectOf("Node").width / 100, closeTo(1, 1e-6));

    await panel.press(LogicalKeyboardKey.equal);

    expect(panel.graph.rectOf("Node").width / 100, greaterThan(1));
  });

  testWidgets("minus zooms out", (tester) async {
    final focus = testFocusNode("Node");
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [graphNode("Node", focusNode: focus)],
          edges: const [],
        ),
      ),
    );
    await panel.requestFocus(focus);

    await panel.press(LogicalKeyboardKey.minus);

    expect(panel.graph.rectOf("Node").width / 100, lessThan(1));
  });

  testWidgets("digit 0 resets the zoom", (tester) async {
    final focus = testFocusNode("Node");
    final panel = await tester.pumpGraph(
      Graph(
        data: GraphData(
          cellSize: 50,
          elements: [graphNode("Node", focusNode: focus)],
          edges: const [],
        ),
      ),
    );
    await panel.requestFocus(focus);
    await panel.press(LogicalKeyboardKey.equal);
    expect(panel.graph.rectOf("Node").width / 100, greaterThan(1));

    await panel.press(LogicalKeyboardKey.digit0);

    expect(panel.graph.rectOf("Node").width / 100, closeTo(1, 1e-6));
  });
}
