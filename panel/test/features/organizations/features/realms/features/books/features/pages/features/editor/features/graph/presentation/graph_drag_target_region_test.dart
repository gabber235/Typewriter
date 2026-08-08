import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  group("Graph drag target region", () {
    testWidgets("rejected target blocks graph movement", (tester) async {
      final state = _DropState();
      await _pumpTargetGraph(tester, state: state, accepts: false);

      final gesture = await _dragFromSourceToTarget(tester);

      expect(find.byKey(const ValueKey("rejected-target")), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(state.graphMoves, 0);
      expect(state.targetDrops, 0);
    });

    testWidgets("accepted target receives drop instead of graph", (
      tester,
    ) async {
      final state = _DropState();
      await _pumpTargetGraph(tester, state: state, accepts: true);

      final gesture = await _dragFromSourceToTarget(tester);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(state.targetDrops, 1);
      expect(state.graphMoves, 0);
    });

    testWidgets("source region still allows graph movement", (tester) async {
      final moves = <List<GraphMoveCommitPayload>>[];
      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("source"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (_) => _exclusiveDraggableNode("source"),
          ),
        ],
        edges: const [],
      );

      await _pumpGraph(tester, data: data, onElementsMoved: moves.add);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey("el-source"))),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(moves, hasLength(1));
      expect(moves.single.single.x, 1);
    });
  });
}

class _DropState {
  int graphMoves = 0;
  int targetDrops = 0;
}

class _TestDragData extends GraphDragData {
  const _TestDragData(this.graphId);

  @override
  final GraphIdentifier graphId;
}

Future<void> _pumpTargetGraph(
  WidgetTester tester, {
  required _DropState state,
  required bool accepts,
}) {
  final data = GraphData(
    cellSize: 50,
    elements: [
      GraphElement(
        id: const GraphIdentifier("source"),
        x: 0,
        y: 0,
        width: 2,
        height: 2,
        builder: (_) => _draggableNode("source"),
      ),
      GraphElement(
        id: const GraphIdentifier("target"),
        x: 4,
        y: 0,
        width: 2,
        height: 2,
        builder: (_) => _exclusiveTarget(
          "target",
          accepts: accepts,
          onAccepted: () => state.targetDrops++,
        ),
      ),
    ],
    edges: const [],
  );
  return _pumpGraph(
    tester,
    data: data,
    onElementsMoved: (_) => state.graphMoves++,
  );
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  required GraphData data,
  required GraphMoveCommit onElementsMoved,
}) {
  return tester.pumpTestApp(
    child: Center(
      child: SizedBox(
        width: 800,
        height: 600,
        child: Graph(data: data, onElementsMoved: onElementsMoved),
      ),
    ),
    settle: true,
  );
}

Future<TestGesture> _dragFromSourceToTarget(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey("el-source"))),
  );
  await tester.pump();
  await gesture.moveTo(
    tester.getCenter(find.byKey(const ValueKey("el-target"))),
  );
  await tester.pump();
  return gesture;
}

Widget _draggableNode(String id) {
  return Draggable<GraphDragData>(
    data: _TestDragData(GraphIdentifier(id)),
    feedback: const SizedBox(width: 40, height: 40),
    child: ColoredBox(key: ValueKey("el-$id"), color: Colors.blue),
  );
}

Widget _exclusiveTarget(
  String id, {
  required bool accepts,
  required VoidCallback onAccepted,
}) {
  return GraphDragTargetRegion(
    targetId: GraphIdentifier(id),
    child: DragTarget<GraphDragData>(
      onWillAcceptWithDetails: (_) => accepts,
      onAcceptWithDetails: (_) => onAccepted(),
      builder: (_, candidateData, rejectedData) {
        return ColoredBox(
          key: ValueKey("el-$id"),
          color: rejectedData.isNotEmpty ? Colors.red : Colors.green,
          child: rejectedData.isNotEmpty
              ? SizedBox.expand(key: ValueKey("rejected-$id"))
              : const SizedBox.expand(),
        );
      },
    ),
  );
}

Widget _exclusiveDraggableNode(String id) {
  final data = _TestDragData(GraphIdentifier(id));
  return Builder(
    builder: (context) {
      final graphDrag = GraphDrag.maybeOf(context);
      return Draggable<GraphDragData>(
        data: data,
        onDragStarted: () => graphDrag?.beginDrag(data),
        onDragEnd: (_) => graphDrag?.endDrag(),
        feedback: const SizedBox(width: 40, height: 40),
        child: GraphDragTargetRegion(
          targetId: data.graphId,
          child: DragTarget<GraphDragData>(
            onWillAcceptWithDetails: (_) => false,
            builder: (_, _, _) =>
                ColoredBox(key: ValueKey("el-$id"), color: Colors.blue),
          ),
        ),
      );
    },
  );
}
