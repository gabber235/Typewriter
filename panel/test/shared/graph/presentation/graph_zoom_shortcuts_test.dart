import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("equal zooms in", (tester) async {
    final panel = await tester.pumpFocusedNode("Node");
    expect(panel.graph.rectOf("Node").width / 100, closeTo(1, 1e-6));

    await panel.press(LogicalKeyboardKey.equal);

    expect(panel.graph.rectOf("Node").width / 100, greaterThan(1));
  });

  testWidgets("minus zooms out", (tester) async {
    final panel = await tester.pumpFocusedNode("Node");

    await panel.press(LogicalKeyboardKey.minus);

    expect(panel.graph.rectOf("Node").width / 100, lessThan(1));
  });

  testWidgets("digit 0 resets the zoom", (tester) async {
    final panel = await tester.pumpFocusedNode("Node");
    await panel.press(LogicalKeyboardKey.equal);
    expect(panel.graph.rectOf("Node").width / 100, greaterThan(1));

    await panel.press(LogicalKeyboardKey.digit0);

    expect(panel.graph.rectOf("Node").width / 100, closeTo(1, 1e-6));
  });
}
