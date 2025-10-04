import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_intents.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../test_utils.dart";

BuildContext _graphActionsContext(WidgetTester tester) {
  final actions = find
      .descendant(of: find.byType(Graph), matching: find.byType(Actions))
      .first;
  final descendants = find
      .descendant(of: actions, matching: find.byWidgetPredicate((w) => true))
      .evaluate()
      .toList();
  return descendants.isNotEmpty ? descendants.first : tester.element(actions);
}

void main() {
  setupMocks();

  group("Graph move/resize intents", () {
    testWidgets("GraphMoveIntent moves selected single element", (
      tester,
    ) async {
      final movedCalls = <List<(GraphIdentifier, int, int)>>[];

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
            onElementsDragged: (changes) => movedCalls.add(changes),
            onElementsResize: (_) {},
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
      final (id, x, y) = moved.single;
      expect(id.id, "a");
      expect((x, y), (1, 0));
    });

    testWidgets("GraphMoveIntent moves multiple selected elements", (
      tester,
    ) async {
      final movedCalls = <List<(GraphIdentifier, int, int)>>[];

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
            onElementsDragged: (changes) => movedCalls.add(changes),
            onElementsResize: (_) {},
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

      final sorted = [...moved]..sort((a, b) => a.$1.id.compareTo(b.$1.id));
      // a: (0,-1), b: (3,3)
      expect(sorted[0].$1.id, "a");
      expect((sorted[0].$2, sorted[0].$3), (0, -1));
      expect(sorted[1].$1.id, "b");
      expect((sorted[1].$2, sorted[1].$3), (3, 3));
    });

    testWidgets("GraphResizeIntent resizes selected single element", (
      tester,
    ) async {
      final resizeCalls = <List<(GraphIdentifier, int, int)>>[];

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
            onElementsDragged: (_) {},
            onElementsResize: (changes) => resizeCalls.add(changes),
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
      final (id, w, h) = changes.single;
      expect(id.id, "a");
      expect((w, h), (3, 2));
    });

    testWidgets("GraphResizeIntent batches multiple and enforces min size", (
      tester,
    ) async {
      final resizeCalls = <List<(GraphIdentifier, int, int)>>[];

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
            onElementsDragged: (_) {},
            onElementsResize: (changes) => resizeCalls.add(changes),
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

      final sorted = [...changes]..sort((a, b) => a.$1.id.compareTo(b.$1.id));
      // a: width 2, height 1; b: width 1, height 1 (min size enforced)
      expect(sorted[0].$1.id, "a");
      expect((sorted[0].$2, sorted[0].$3), (2, 1));
      expect(sorted[1].$1.id, "b");
      expect((sorted[1].$2, sorted[1].$3), (1, 1));
    });
  });
}
