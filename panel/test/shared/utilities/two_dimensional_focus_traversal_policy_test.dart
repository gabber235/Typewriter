import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/utilities/two_dimensional_focus_traversal_policy.dart";

import "../../support/test_utils.dart";

typedef _NodePlacement = ({
  String id,
  int left,
  int top,
  int width,
  int height,
});

Future<Map<String, FocusNode>> _pumpTraversalScene(
  WidgetTester tester, {
  required Axis mainAxis,
  required List<_NodePlacement> placements,
  double crossAxisBandTolerance = 12.0,
  TraversalEdgeBehavior directionalTraversalEdgeBehavior =
      TraversalEdgeBehavior.stop,
}) async {
  final nodes = <String, FocusNode>{
    for (final placement in placements)
      placement.id: FocusNode(debugLabel: placement.id),
  };
  final scopeNode = FocusScopeNode(
    directionalTraversalEdgeBehavior: directionalTraversalEdgeBehavior,
  );
  addTearDown(() {
    for (final node in nodes.values) {
      node.dispose();
    }
    scopeNode.dispose();
  });

  await tester.pumpTestApp(
    child: FocusTraversalGroup(
      policy: TwoDFocusTraversalPolicy(
        mainAxis: mainAxis,
        crossAxisBandTolerance: crossAxisBandTolerance,
      ),
      child: FocusScope.withExternalFocusNode(
        focusScopeNode: scopeNode,
        child: SizedBox(
          width: 600,
          height: 600,
          child: Stack(
            children: [
              for (final placement in placements)
                Positioned(
                  left: placement.left.toDouble(),
                  top: placement.top.toDouble(),
                  width: placement.width.toDouble(),
                  height: placement.height.toDouble(),
                  child: Focus(
                    focusNode: nodes[placement.id],
                    child: SizedBox.expand(key: ValueKey<String>(placement.id)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return nodes;
}

Future<void> _requestFocus(WidgetTester tester, FocusNode node) async {
  node.requestFocus();
  await tester.pumpAndSettle();
}

Future<void> _sendShiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Future<void> _sendArrow(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void _expectPrimary(Map<String, FocusNode> nodes, String id) {
  expect(nodes[id]?.hasPrimaryFocus, isTrue);
}

void _expectNoPrimary(Map<String, FocusNode> nodes) {
  for (final node in nodes.values) {
    expect(node.hasPrimaryFocus, isFalse);
  }
}

void main() {
  group("TwoDFocusTraversalPolicy tab traversal", () {
    testWidgets("horizontal main axis traverses by row bands", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "a", left: 0, top: 0, width: 50, height: 40),
          (id: "b", left: 80, top: 5, width: 50, height: 40),
          (id: "c", left: 160, top: 2, width: 50, height: 40),
          (id: "d", left: 0, top: 80, width: 50, height: 40),
          (id: "e", left: 80, top: 76, width: 50, height: 40),
          (id: "f", left: 160, top: 82, width: 50, height: 40),
        ],
      );

      await _requestFocus(tester, nodes["a"]!);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "b");

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "c");

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "d");

      await _sendShiftTab(tester);
      _expectPrimary(nodes, "c");
    });

    testWidgets("vertical main axis traverses by column bands", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.vertical,
        placements: [
          (id: "a", left: 0, top: 0, width: 50, height: 40),
          (id: "b", left: 4, top: 80, width: 50, height: 40),
          (id: "c", left: 2, top: 160, width: 50, height: 40),
          (id: "d", left: 90, top: 0, width: 50, height: 40),
          (id: "e", left: 92, top: 80, width: 50, height: 40),
          (id: "f", left: 94, top: 160, width: 50, height: 40),
        ],
      );

      await _requestFocus(tester, nodes["a"]!);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "b");

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "c");

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      _expectPrimary(nodes, "d");
    });

    testWidgets("tab ordering changes when tolerance includes boundary node", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        crossAxisBandTolerance: 12.0,
        placements: [
          (id: "a", left: 100, top: 0, width: 40, height: 40),
          (id: "b", left: 0, top: 52, width: 40, height: 40),
          (id: "c", left: 200, top: 120, width: 40, height: 40),
        ],
      );

      await _requestFocus(tester, nodes["a"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      _expectPrimary(nodes, "c");
    });

    testWidgets("tab ordering changes when tolerance excludes boundary node", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        crossAxisBandTolerance: 11.0,
        placements: [
          (id: "a", left: 100, top: 0, width: 40, height: 40),
          (id: "b", left: 0, top: 52, width: 40, height: 40),
          (id: "c", left: 200, top: 120, width: 40, height: 40),
        ],
      );

      await _requestFocus(tester, nodes["a"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      _expectPrimary(nodes, "b");
    });
  });

  group("TwoDFocusTraversalPolicy directional traversal", () {
    testWidgets("unfocused scope picks first node for up", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "top_left", left: 0, top: 0, width: 40, height: 40),
          (id: "top_right", left: 200, top: 20, width: 40, height: 40),
          (id: "bottom_left", left: 20, top: 180, width: 40, height: 40),
          (id: "bottom_right", left: 220, top: 200, width: 40, height: 40),
        ],
      );

      final policy = TwoDFocusTraversalPolicy(mainAxis: Axis.horizontal);
      final first = policy.findFirstFocusInDirection(
        nodes["top_left"]!,
        TraversalDirection.up,
      );

      expect(first, same(nodes["bottom_right"]));
    });

    testWidgets("unfocused scope picks first node for down", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "top_left", left: 0, top: 0, width: 40, height: 40),
          (id: "top_right", left: 200, top: 20, width: 40, height: 40),
          (id: "bottom_left", left: 20, top: 180, width: 40, height: 40),
          (id: "bottom_right", left: 220, top: 200, width: 40, height: 40),
        ],
      );

      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);
      _expectPrimary(nodes, "top_left");
    });

    testWidgets("unfocused scope picks first node for left", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "top_left", left: 0, top: 0, width: 40, height: 40),
          (id: "top_right", left: 200, top: 20, width: 40, height: 40),
          (id: "bottom_left", left: 20, top: 180, width: 40, height: 40),
          (id: "bottom_right", left: 220, top: 200, width: 40, height: 40),
        ],
      );

      final policy = TwoDFocusTraversalPolicy(mainAxis: Axis.horizontal);
      final first = policy.findFirstFocusInDirection(
        nodes["top_left"]!,
        TraversalDirection.left,
      );

      expect(first, same(nodes["bottom_right"]));
    });

    testWidgets("unfocused scope picks first node for right", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "top_left", left: 0, top: 0, width: 40, height: 40),
          (id: "top_right", left: 200, top: 20, width: 40, height: 40),
          (id: "bottom_left", left: 20, top: 180, width: 40, height: 40),
          (id: "bottom_right", left: 220, top: 200, width: 40, height: 40),
        ],
      );

      await _sendArrow(tester, LogicalKeyboardKey.arrowRight);
      _expectPrimary(nodes, "top_left");
    });

    testWidgets("down rejects same level and above", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "current", left: 100, top: 100, width: 50, height: 50),
          (id: "same", left: 230, top: 100, width: 50, height: 50),
          (id: "above", left: 120, top: 30, width: 50, height: 50),
          (id: "below", left: 260, top: 200, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["current"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "below");
    });

    testWidgets("down keeps large angle forward candidates eligible", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "current", left: 100, top: 100, width: 50, height: 50),
          (id: "above_left", left: 10, top: 20, width: 50, height: 50),
          (id: "diag", left: 340, top: 170, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["current"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "diag");
    });

    testWidgets("down prefers nearby aligned candidate over far diagonal", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "current", left: 100, top: 100, width: 50, height: 50),
          (id: "aligned", left: 104, top: 175, width: 50, height: 50),
          (id: "diagonal", left: 340, top: 160, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["current"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "aligned");
    });

    testWidgets("directional traversal skips nodes that cannot request focus", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "current", left: 100, top: 100, width: 50, height: 50),
          (id: "blocked", left: 104, top: 170, width: 50, height: 50),
          (id: "allowed", left: 110, top: 260, width: 50, height: 50),
        ],
      );

      nodes["blocked"]!.canRequestFocus = false;

      await _requestFocus(tester, nodes["current"]!);
      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "allowed");
    });

    testWidgets("directional traversal skips nodes marked skipTraversal", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "current", left: 100, top: 100, width: 50, height: 50),
          (id: "skipped", left: 104, top: 170, width: 50, height: 50),
          (id: "allowed", left: 110, top: 260, width: 50, height: 50),
        ],
      );

      nodes["skipped"]!.skipTraversal = true;

      await _requestFocus(tester, nodes["current"]!);
      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "allowed");
    });

    testWidgets("orthogonal switch clears old history before reverse", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "center", left: 120, top: 120, width: 50, height: 50),
          (id: "right", left: 230, top: 120, width: 50, height: 50),
          (id: "up", left: 230, top: 20, width: 50, height: 50),
          (id: "upper_left", left: 40, top: 20, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["center"]!);

      await _sendArrow(tester, LogicalKeyboardKey.arrowRight);
      _expectPrimary(nodes, "right");

      await _sendArrow(tester, LogicalKeyboardKey.arrowUp);
      _expectPrimary(nodes, "up");

      await _sendArrow(tester, LogicalKeyboardKey.arrowLeft);
      _expectPrimary(nodes, "upper_left");
    });

    testWidgets("opposite direction pops history path", (tester) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        placements: [
          (id: "a", left: 0, top: 0, width: 50, height: 50),
          (id: "b", left: 90, top: 0, width: 50, height: 50),
          (id: "c", left: 180, top: 0, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["b"]!);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      _expectPrimary(nodes, "c");

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      _expectPrimary(nodes, "b");
    });

    testWidgets("closed loop wraps when direction has no candidate", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        placements: [
          (id: "top", left: 100, top: 0, width: 50, height: 50),
          (id: "bottom", left: 100, top: 240, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["bottom"]!);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "top");
    });

    testWidgets("stop edge behavior keeps focus on current node", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop,
        placements: [
          (id: "top", left: 100, top: 0, width: 50, height: 50),
          (id: "bottom", left: 100, top: 240, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["bottom"]!);
      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);

      _expectPrimary(nodes, "bottom");
    });

    testWidgets("leaveFlutterView edge behavior clears primary focus", (
      tester,
    ) async {
      final nodes = await _pumpTraversalScene(
        tester,
        mainAxis: Axis.horizontal,
        directionalTraversalEdgeBehavior:
            TraversalEdgeBehavior.leaveFlutterView,
        placements: [
          (id: "top", left: 100, top: 0, width: 50, height: 50),
          (id: "bottom", left: 100, top: 240, width: 50, height: 50),
        ],
      );

      await _requestFocus(tester, nodes["bottom"]!);
      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);

      _expectNoPrimary(nodes);
    });

    testWidgets("parentScope edge behavior can traverse into parent scope", (
      tester,
    ) async {
      final currentNode = FocusNode(debugLabel: "current");
      final parentNode = FocusNode(debugLabel: "parent");
      final rootScopeNode = FocusScopeNode();
      final childScopeNode = FocusScopeNode(
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
      );

      addTearDown(() {
        currentNode.dispose();
        parentNode.dispose();
        rootScopeNode.dispose();
        childScopeNode.dispose();
      });

      await tester.pumpTestApp(
        child: FocusTraversalGroup(
          policy: TwoDFocusTraversalPolicy(mainAxis: Axis.horizontal),
          child: FocusScope.withExternalFocusNode(
            focusScopeNode: rootScopeNode,
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
                    child: Focus(
                      focusNode: parentNode,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    left: 100,
                    top: 100,
                    width: 40,
                    height: 40,
                    child: FocusScope.withExternalFocusNode(
                      focusScopeNode: childScopeNode,
                      child: Focus(
                        focusNode: currentNode,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await _requestFocus(tester, currentNode);
      await _sendArrow(tester, LogicalKeyboardKey.arrowDown);

      expect(parentNode.hasPrimaryFocus, isTrue);
    });
  });
}
