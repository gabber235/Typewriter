import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("Graph move focus", () {
    testWidgets("routes an immediate arrow through the newly activated mode", (
      tester,
    ) async {
      final (:panel, :focusNodes, :calls) = await tester.pumpMovableGraph(
        ids: const ["a", "b"],
        selection: (focused) => [focused["a"]!, focused["b"]!],
      );
      focusNodes["a"]!.requestFocus();
      await tester.pumpAndSettle();

      await panel.pressMoveModeKeysWithoutPump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(calls, hasLength(1));
      expect({for (final change in calls.single) change.id.id}, {"a", "b"});
      expect(focusNodes["a"]!.hasPrimaryFocus, isTrue);
    });

    testWidgets("accumulates held key repeats before the next frame", (
      tester,
    ) async {
      final (:panel, :focusNodes, :calls) = await tester.pumpMovableGraph(
        ids: const ["a"],
        selection: (focused) => [focused["a"]!],
      );
      final focusNode = focusNodes["a"]!..requestFocus();
      await tester.pump();
      await panel.enterMoveMode();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      for (var index = 0; index < 20; index++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(calls, hasLength(21));
      expect(
        calls.map((call) => call.single.x),
        orderedEquals(List.generate(21, (index) => index + 1)),
      );
      expect(focusNode.hasPrimaryFocus, isTrue);
    });

    for (final (focused, moved) in [
      ("a", ["a", "b"]),
      ("c", ["c"]),
    ]) {
      testWidgets(
        "an arrow with focus on ${focused == "a" ? "a selected" : "an unselected"} "
        "node moves ${moved.join(" and ")}",
        (tester) async {
          final (:panel, :focusNodes, :calls) = await tester.pumpMovableGraph(
            ids: const ["a", "b", "c"],
            selection: (_) => [
              GraphSelectableIdentifier(id: "a"),
              GraphSelectableIdentifier(id: "b"),
            ],
          );
          focusNodes[focused]!.requestFocus();
          await tester.pump();

          await panel.enterMoveMode();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();

          expect(calls, hasLength(1));
          expect([
            for (final change in calls.single) change.id.id,
          ], unorderedEquals(moved));
          expect(focusNodes[focused]!.hasPrimaryFocus, isTrue);
        },
      );
    }

    final arrows = [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
    ];
    final random = Random(240804);
    for (final (name, moves, key, pause) in [
      (
        "repeated committed",
        30,
        (int _) => LogicalKeyboardKey.arrowRight,
        (int _) => const Duration(milliseconds: 16),
      ),
      (
        "seeded mixed",
        60,
        (int _) => arrows[random.nextInt(arrows.length)],
        (int index) => Duration(milliseconds: [0, 4, 16][index % 3]),
      ),
    ]) {
      testWidgets("retains focus through $name movement", (tester) async {
        final (:panel, :focusNodes, :calls) = await tester.pumpMovableGraph(
          ids: const ["a"],
          selection: (focused) => [focused["a"]!],
          size: const Size(400, 300),
        );
        final focusNode = focusNodes["a"]!..requestFocus();
        await tester.pump();
        await panel.enterMoveMode();

        for (var index = 0; index < moves; index++) {
          await tester.sendKeyEvent(key(index));
          await tester.pump(pause(index));

          expect(calls, hasLength(index + 1), reason: "move ${index + 1}");
          expect(
            focusNode.hasPrimaryFocus,
            isTrue,
            reason: "move ${index + 1}",
          );
          expect(panel.graph.hasNode("a"), isTrue);
        }
      });
    }
  });
}
