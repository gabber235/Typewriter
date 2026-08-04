import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

BuildContext _graphActionsContext(WidgetTester tester) {
  final actions = find.byWidgetPredicate(
    (w) => w is Actions && w.actions.containsKey(GraphMoveIntent),
  );
  final descendants = find
      .descendant(of: actions, matching: find.byWidgetPredicate((w) => true))
      .evaluate()
      .toList();
  return descendants.isNotEmpty ? descendants.first : tester.element(actions);
}

void main() {
  group("Graph move/resize intents", () {
    testWidgets("GraphMoveIntent moves selected single element", (
      tester,
    ) async {
      final movedCalls = <List<GraphMoveCommitPayload>>[];

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) => const SizedBox.shrink(),
          ),
          GraphElement(
            id: const GraphIdentifier("b"),
            x: 3,
            y: 4,
            width: 1,
            height: 1,
            builder: (context) => const SizedBox.shrink(),
          ),
        ],
        edges: const [],
      );

      final overrides = [
        selectionProvider.overrideWithValue([
          TestSelectableIdentifier(id: "a"),
        ]),
      ];

      await tester.pumpTestApp(
        overrides: overrides,
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(
            data: data,
            onElementsMoved: movedCalls.add,
            onElementsResized: (_) {},
          ),
        ),
      );

      final actionsCtx = _graphActionsContext(tester);
      Actions.invoke(
        actionsCtx,
        const GraphMoveIntent(direction: TraversalDirection.right),
      );
      await tester.pump();

      expect(movedCalls.length, 1);
      final moved = movedCalls.single;
      expect(moved.length, 1);
      final change = moved.single;
      expect(change.id.id, "a");
      expect((change.x, change.y), (1, 0));
    });

    testWidgets("GraphMoveIntent moves multiple selected elements", (
      tester,
    ) async {
      final movedCalls = <List<GraphMoveCommitPayload>>[];

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) => const SizedBox.shrink(),
          ),
          GraphElement(
            id: const GraphIdentifier("b"),
            x: 3,
            y: 4,
            width: 1,
            height: 1,
            builder: (context) => const SizedBox.shrink(),
          ),
        ],
        edges: const [],
      );

      final overrides = [
        selectionProvider.overrideWithValue([
          TestSelectableIdentifier(id: "a"),
          TestSelectableIdentifier(id: "b"),
        ]),
      ];

      await tester.pumpTestApp(
        overrides: overrides,
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(
            data: data,
            onElementsMoved: movedCalls.add,
            onElementsResized: (_) {},
          ),
        ),
      );

      final actionsCtx = _graphActionsContext(tester);
      Actions.invoke(
        actionsCtx,
        const GraphMoveIntent(direction: TraversalDirection.up),
      );
      await tester.pump();

      expect(movedCalls.length, 1);
      final moved = movedCalls.single;
      expect(moved.length, 2);

      final sorted = [...moved]..sort((a, b) => a.id.id.compareTo(b.id.id));
      expect(sorted[0].id.id, "a");
      expect((sorted[0].x, sorted[0].y), (0, -1));
      expect(sorted[1].id.id, "b");
      expect((sorted[1].x, sorted[1].y), (3, 3));
    });

    testWidgets("GraphResizeIntent resizes selected single element", (
      tester,
    ) async {
      final resizeCalls = <List<GraphResizeCommitPayload>>[];

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) => const SizedBox.shrink(),
          ),
        ],
        edges: const [],
      );

      final overrides = [
        selectionProvider.overrideWithValue([
          TestSelectableIdentifier(id: "a"),
        ]),
      ];

      await tester.pumpTestApp(
        overrides: overrides,
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(
            data: data,
            onElementsMoved: (_) {},
            onElementsResized: resizeCalls.add,
          ),
        ),
      );

      final actionsCtx = _graphActionsContext(tester);
      Actions.invoke(
        actionsCtx,
        const GraphResizeIntent(direction: TraversalDirection.right),
      );
      await tester.pump();

      expect(resizeCalls.length, 1);
      final changes = resizeCalls.single;
      expect(changes.length, 1);
      final change = changes.single;
      expect(change.id.id, "a");
      expect((change.width, change.height), (3, 2));
    });

    testWidgets("GraphResizeIntent batches multiple and enforces min size", (
      tester,
    ) async {
      final resizeCalls = <List<GraphResizeCommitPayload>>[];

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) => const SizedBox.shrink(),
          ),
          GraphElement(
            id: const GraphIdentifier("b"),
            x: 3,
            y: 4,
            width: 1,
            height: 1,
            builder: (context) => const SizedBox.shrink(),
          ),
        ],
        edges: const [],
      );

      final overrides = [
        selectionProvider.overrideWithValue([
          TestSelectableIdentifier(id: "a"),
          TestSelectableIdentifier(id: "b"),
        ]),
      ];

      await tester.pumpTestApp(
        overrides: overrides,
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(
            data: data,
            onElementsMoved: (_) {},
            onElementsResized: resizeCalls.add,
          ),
        ),
      );

      final actionsCtx = _graphActionsContext(tester);
      Actions.invoke(
        actionsCtx,
        const GraphResizeIntent(direction: TraversalDirection.up),
      );
      await tester.pump();

      expect(resizeCalls.length, 1);
      final changes = resizeCalls.single;
      expect(changes.length, 2);

      final sorted = [...changes]..sort((a, b) => a.id.id.compareTo(b.id.id));
      expect(sorted[0].id.id, "a");
      expect((sorted[0].width, sorted[0].height), (2, 1));
      expect(sorted[1].id.id, "b");
      expect((sorted[1].width, sorted[1].height), (1, 1));
    });
  });
}
