import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  // Node "a" (2 by 2 at 0, 0) and node "b" (1 by 1 at 3, 4).
  for (final (selected, key, expected) in [
    (["a"], LogicalKeyboardKey.arrowRight, {"a": (1, 0)}),
    (["a", "b"], LogicalKeyboardKey.arrowUp, {"a": (0, -1), "b": (3, 3)}),
  ]) {
    testWidgets("move mode moves the selected ${selected.join(" and ")} with "
        "${key.keyLabel}", (tester) async {
      final focus = FocusNode(debugLabel: "a");
      addTearDown(focus.dispose);
      final (:panel, :moves, resizes: _) = await tester.pumpCommittingGraph([
        graphNode("a", focusNode: focus),
        graphNode("b", x: 3, y: 4, cells: 1),
      ], resizable: true);
      panel.container.read(selectionProvider.notifier).selectAll([
        for (final id in selected) TestSelectableIdentifier(id: id),
      ]);
      focus.requestFocus();
      await panel.settle();
      await panel.graph.shiftPress(LogicalKeyboardKey.keyM);

      await panel.press(key);

      expect(moves, hasLength(1));
      expect({
        for (final move in moves.single) move.id.id: (move.x, move.y),
      }, expected);
    });
  }

  for (final (selected, key, expected) in [
    (["a"], LogicalKeyboardKey.arrowRight, {"a": (3, 2)}),
    (["a", "b"], LogicalKeyboardKey.arrowUp, {"a": (2, 1), "b": (1, 1)}),
  ]) {
    testWidgets("resize mode resizes the selected ${selected.join(" and ")} "
        "with ${key.keyLabel}, never below one cell", (tester) async {
      final focus = FocusNode(debugLabel: "a");
      addTearDown(focus.dispose);
      final (:panel, :resizes, moves: _) = await tester.pumpCommittingGraph([
        graphNode("a", focusNode: focus),
        graphNode("b", x: 3, y: 4, cells: 1),
      ], resizable: true);
      panel.container.read(selectionProvider.notifier).selectAll([
        for (final id in selected) TestSelectableIdentifier(id: id),
      ]);
      focus.requestFocus();
      await panel.settle();
      await panel.graph.shiftPress(LogicalKeyboardKey.keyR);

      await panel.press(key);

      expect(resizes, hasLength(1));
      expect({
        for (final resize in resizes.single)
          resize.id.id: (resize.width, resize.height),
      }, expected);
    });
  }
}
