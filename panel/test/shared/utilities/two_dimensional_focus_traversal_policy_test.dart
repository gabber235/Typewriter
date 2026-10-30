import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("TwoDFocusTraversalPolicy tab traversal", () {
    testWidgets("horizontal main axis traverses by row bands", (tester) async {
      final boxes = [
        FocusBox("a", 0, 0, 50, 40),
        FocusBox("b", 80, 5, 50, 40),
        FocusBox("c", 160, 2, 50, 40),
        FocusBox("d", 0, 80, 50, 40),
        FocusBox("e", 80, 76, 50, 40),
        FocusBox("f", 160, 82, 50, 40),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["a"]!);

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "b");

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "c");

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "d");

      await panel.pressShifted(LogicalKeyboardKey.tab);
      expect(panel.focused, "c");
    });

    testWidgets("vertical main axis traverses by column bands", (tester) async {
      final boxes = [
        FocusBox("a", 0, 0, 50, 40),
        FocusBox("b", 4, 80, 50, 40),
        FocusBox("c", 2, 160, 50, 40),
        FocusBox("d", 90, 0, 50, 40),
        FocusBox("e", 92, 80, 50, 40),
        FocusBox("f", 94, 160, 50, 40),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.vertical,
      );

      await panel.requestFocus(nodes["a"]!);

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "b");

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "c");

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "d");
    });

    for (final (tolerance, verb, next) in [
      (12.0, "includes", "c"),
      (11.0, "excludes", "b"),
    ]) {
      testWidgets("tab ordering changes when tolerance $verb boundary node", (
        tester,
      ) async {
        final boxes = [
          FocusBox("a", 100, 0, 40, 40),
          FocusBox("b", 0, 52, 40, 40),
          FocusBox("c", 200, 120, 40, 40),
        ];
        final (panel, nodes) = await tester.showFocusBoxes(
          boxes,
          mainAxis: Axis.horizontal,
          crossAxisBandTolerance: tolerance,
        );

        await panel.requestFocus(nodes["a"]!);
        await panel.press(LogicalKeyboardKey.tab);

        expect(panel.focused, next);
      });
    }
  });

  group("TwoDFocusTraversalPolicy directional traversal", () {
    final grid = [
      FocusBox("top_left", 0, 0, 40, 40),
      FocusBox("top_right", 200, 20, 40, 40),
      FocusBox("bottom_left", 20, 180, 40, 40),
      FocusBox("bottom_right", 220, 200, 40, 40),
    ];

    for (final direction in [TraversalDirection.up, TraversalDirection.left]) {
      testWidgets("unfocused scope picks first node for ${direction.name}", (
        tester,
      ) async {
        final (_, nodes) = await tester.showFocusBoxes(
          grid,
          mainAxis: Axis.horizontal,
        );

        final policy = TwoDFocusTraversalPolicy(mainAxis: Axis.horizontal);
        final first = policy.findFirstFocusInDirection(
          nodes["top_left"]!,
          direction,
        );

        expect(first, same(nodes["bottom_right"]));
      });
    }

    for (final (direction, key) in [
      ("down", LogicalKeyboardKey.arrowDown),
      ("right", LogicalKeyboardKey.arrowRight),
    ]) {
      testWidgets("unfocused scope picks first node for $direction", (
        tester,
      ) async {
        final (panel, nodes) = await tester.showFocusBoxes(
          grid,
          mainAxis: Axis.horizontal,
        );

        await panel.press(key);
        expect(panel.focused, "top_left");
      });
    }

    testWidgets("down rejects same level and above", (tester) async {
      final boxes = [
        FocusBox("current", 100, 100, 50, 50),
        FocusBox("same", 230, 100, 50, 50),
        FocusBox("above", 120, 30, 50, 50),
        FocusBox("below", 260, 200, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "below");
    });

    testWidgets("down keeps large angle forward candidates eligible", (
      tester,
    ) async {
      final boxes = [
        FocusBox("current", 100, 100, 50, 50),
        FocusBox("above_left", 10, 20, 50, 50),
        FocusBox("diag", 340, 170, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "diag");
    });

    testWidgets("down prefers nearby aligned candidate over far diagonal", (
      tester,
    ) async {
      final boxes = [
        FocusBox("current", 100, 100, 50, 50),
        FocusBox("aligned", 104, 175, 50, 50),
        FocusBox("diagonal", 340, 160, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "aligned");
    });

    testWidgets("directional traversal skips nodes that cannot request focus", (
      tester,
    ) async {
      final boxes = [
        FocusBox("current", 100, 100, 50, 50),
        FocusBox("blocked", 104, 170, 50, 50),
        FocusBox("allowed", 110, 260, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      nodes["blocked"]!.canRequestFocus = false;

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "allowed");
    });

    testWidgets("directional traversal skips nodes marked skipTraversal", (
      tester,
    ) async {
      final boxes = [
        FocusBox("current", 100, 100, 50, 50),
        FocusBox("skipped", 104, 170, 50, 50),
        FocusBox("allowed", 110, 260, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      nodes["skipped"]!.skipTraversal = true;

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "allowed");
    });

    testWidgets("orthogonal switch clears old history before reverse", (
      tester,
    ) async {
      final boxes = [
        FocusBox("center", 120, 120, 50, 50),
        FocusBox("right", 230, 120, 50, 50),
        FocusBox("up", 230, 20, 50, 50),
        FocusBox("upper_left", 40, 20, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["center"]!);

      await panel.press(LogicalKeyboardKey.arrowRight);
      expect(panel.focused, "right");

      await panel.press(LogicalKeyboardKey.arrowUp);
      expect(panel.focused, "up");

      await panel.press(LogicalKeyboardKey.arrowLeft);
      expect(panel.focused, "upper_left");
    });

    testWidgets("opposite direction pops history path", (tester) async {
      final boxes = [
        FocusBox("a", 0, 0, 50, 50),
        FocusBox("b", 90, 0, 50, 50),
        FocusBox("c", 180, 0, 50, 50),
      ];
      final (panel, nodes) = await tester.showFocusBoxes(
        boxes,
        mainAxis: Axis.horizontal,
      );

      await panel.requestFocus(nodes["b"]!);

      await panel.press(LogicalKeyboardKey.arrowRight);
      expect(panel.focused, "c");

      await panel.press(LogicalKeyboardKey.arrowLeft);
      expect(panel.focused, "b");
    });

    for (final (name, behavior, focused)
        in <(String, TraversalEdgeBehavior, Matcher)>[
          (
            "closed loop wraps when direction has no candidate",
            TraversalEdgeBehavior.closedLoop,
            equals("top"),
          ),
          (
            "stop edge behavior keeps focus on current node",
            TraversalEdgeBehavior.stop,
            equals("bottom"),
          ),
          (
            "leaveFlutterView edge behavior clears primary focus",
            TraversalEdgeBehavior.leaveFlutterView,
            isNot(isIn(["top", "bottom"])),
          ),
        ]) {
      testWidgets(name, (tester) async {
        final boxes = [
          FocusBox("top", 100, 0, 50, 50),
          FocusBox("bottom", 100, 240, 50, 50),
        ];
        final (panel, nodes) = await tester.showFocusBoxes(
          boxes,
          mainAxis: Axis.horizontal,
          edgeBehavior: behavior,
        );

        await panel.requestFocus(nodes["bottom"]!);
        await panel.press(LogicalKeyboardKey.arrowDown);

        expect(panel.focused, focused);
      });
    }

    testWidgets("parentScope edge behavior can traverse into parent scope", (
      tester,
    ) async {
      final nodes = focusNodesFor(const [
        FocusBox("current", 100, 100, 40, 40),
        FocusBox("parent", 200, 260, 40, 40),
      ]);
      Widget box(String id) => Semantics(
        container: true,
        label: id,
        child: Focus(focusNode: nodes[id], child: const SizedBox.expand()),
      );
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          HookBuilder(
            builder: (context) {
              final childScope = useEdgeScope(
                TraversalEdgeBehavior.parentScope,
              );
              return FocusTraversalGroup(
                policy: TwoDFocusTraversalPolicy(mainAxis: Axis.horizontal),
                child: FocusScope(
                  child: SizedBox(
                    width: 500,
                    height: 500,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 200,
                          top: 260,
                          width: 40,
                          height: 40,
                          child: box("parent"),
                        ),
                        Positioned(
                          left: 100,
                          top: 100,
                          width: 40,
                          height: 40,
                          child: FocusScope.withExternalFocusNode(
                            focusScopeNode: childScope,
                            child: box("current"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await panel.requestFocus(nodes["current"]!);
      await panel.press(LogicalKeyboardKey.arrowDown);

      expect(panel.focused, "parent");
    });
  });
}
