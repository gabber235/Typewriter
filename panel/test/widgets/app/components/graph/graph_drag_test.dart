import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";

import "../../../../test_utils.dart";

void main() {
  setupMocks();

  group("Graph - drag and drop", () {
    testWidgets("accepts drag and commits snapped grid delta", (tester) async {
      const cell = 50.0;

      final updates = <List<(GraphIdentifier, int, int)>>[];
      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 2,
            y: 3,
            width: 2,
            height: 2,
            builder: (_) => _draggableNode("a", color: Colors.blue),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: data, onElementsDragged: updates.add),
          ),
        ),
        settle: true,
      );

      final aFinder = find.byKey(const ValueKey("el-a"));
      expect(aFinder, findsOneWidget);

      final start = tester.getCenter(aFinder);
      final target =
          tester.getTopLeft(aFinder) + const Offset(cell * 1, cell * 2);

      final g = await tester.startGesture(start);
      await tester.pump();
      await g.moveTo(target);
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      final last = updates.last;
      expect(last, hasLength(1));
      expect(last.first.$1, const GraphIdentifier("a"));
      expect(last.first.$2, 2 + 1);
      expect(last.first.$3, 3 + 2);
    });

    testWidgets("snaps using .round(): <0.5 cell -> 0, >=0.5 cell -> 1", (
      tester,
    ) async {
      const cell = 50.0;
      final dragInside = ValueNotifier<bool>(false);
      var accepted = 0;

      (GraphIdentifier, int, int)? lastCall;
      void onDragged(List<(GraphIdentifier, int, int)> u) {
        lastCall = u.single;
      }

      GraphElement elementBuilder(String id) => GraphElement(
        id: GraphIdentifier(id),
        x: 0,
        y: 0,
        width: 2,
        height: 2,
        builder: (_) => _DragStateProbe(
          sink: dragInside,
          child: _draggableNode(id, color: Colors.green),
        ),
      );

      Future<void> pumpGraph() async {
        lastCall = null;
        await tester.pumpTestApp(
          child: Center(
            child: SizedBox(
              width: 600,
              height: 400,
              child: Graph(
                data: GraphData(
                  cellSize: cell,
                  elements: [elementBuilder("snap")],
                  edges: const [],
                ),
                onElementsDragged: (u) {
                  accepted++;
                  onDragged(u);
                },
              ),
            ),
          ),
          settle: true,
        );
      }

      await pumpGraph();
      final snapFinder = find.byKey(const ValueKey("el-snap"));
      expect(snapFinder, findsOneWidget);

      final startTopLeft = tester.getTopLeft(snapFinder);
      var g = await tester.startGesture(startTopLeft);
      await tester.pump();
      await g.moveTo(startTopLeft + const Offset(24, 0));
      await tester.pump();
      expect(dragInside.value, isTrue);
      await g.up();
      await tester.pumpAndSettle();

      expect(accepted, greaterThanOrEqualTo(1));
      expect(lastCall, isNotNull);
      expect(lastCall!.$1, const GraphIdentifier("snap"));
      expect(lastCall!.$2, 0);
      expect(lastCall!.$3, 0);

      await pumpGraph();

      g = await tester.startGesture(startTopLeft);
      await tester.pump();
      await g.moveTo(startTopLeft + const Offset(25, 0));
      await tester.pump();
      expect(dragInside.value, isTrue);
      await g.up();
      await tester.pumpAndSettle();

      expect(accepted, greaterThanOrEqualTo(2));
      expect(lastCall, isNotNull);
      expect(lastCall!.$1, const GraphIdentifier("snap"));
      expect(lastCall!.$2, 1);
      expect(lastCall!.$3, 0);
    });

    testWidgets("dragging a container moves elements fully inside it", (
      tester,
    ) async {
      const cell = 50.0;

      List<(GraphIdentifier, int, int)>? a;
      List<(GraphIdentifier, int, int)>? b;

      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("parent"),
            x: 1,
            y: 1,
            width: 4,
            height: 4,
            builder: (_) => _draggableNode("parent", color: Colors.orange),
          ),
          GraphElement(
            id: const GraphIdentifier("child"),
            x: 2,
            y: 2,
            width: 1,
            height: 1,
            builder: (_) => _draggableNode("child", color: Colors.purple),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1000,
            height: 700,
            child: Graph(
              data: data,
              onElementsDragged: (u) {
                for (final entry in u) {
                  if (entry.$1 == const GraphIdentifier("parent")) {
                    a = u;
                  }
                  if (entry.$1 == const GraphIdentifier("child")) {
                    b = u;
                  }
                }
              },
            ),
          ),
        ),
        settle: true,
      );

      final parentFinder = find.byKey(const ValueKey("el-parent"));
      expect(parentFinder, findsOneWidget);
      expect(find.byKey(const ValueKey("el-child")), findsOneWidget);

      final start = tester.getCenter(parentFinder);
      final target =
          tester.getTopLeft(parentFinder) + const Offset(cell * 2, cell * 1);

      final g = await tester.startGesture(start);
      await tester.pump();
      await g.moveTo(target);
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();

      expect(a, isNotNull);
      final moved = a!;
      expect(moved.length, 2);

      final movedMap = {for (final e in moved) e.$1: (e.$2, e.$3)};

      expect(movedMap[const GraphIdentifier("parent")], (1 + 2, 1 + 1));
      expect(movedMap[const GraphIdentifier("child")], (2 + 2, 2 + 1));

      expect(b, isNotNull);
      expect(b, moved);
    });

    testWidgets("rejects drags with unknown graphId (no commit)", (
      tester,
    ) async {
      const cell = 50.0;

      var calls = 0;
      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (_) => _draggableNode("unknown", color: Colors.teal),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: data, onElementsDragged: (_) => calls++),
          ),
        ),
        settle: true,
      );

      final finder = find.byKey(const ValueKey("el-unknown"));
      expect(finder, findsOneWidget);

      final g = await tester.startGesture(tester.getCenter(finder));
      await tester.pump();
      await g.moveBy(const Offset(80, 40));
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}

class _TestDragData extends GraphDragData {
  const _TestDragData(this.graphId);
  @override
  final GraphIdentifier graphId;
}

Widget _draggableNode(String id, {Color? color}) {
  return Draggable<GraphDragData>(
    data: _TestDragData(GraphIdentifier(id)),
    feedback: Material(
      elevation: 2,
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        child: ColoredBox(color: (color ?? Colors.red).withValues(alpha: 0.8)),
      ),
    ),
    child: RepaintBoundary(
      key: ValueKey("el-$id"),
      child: ColoredBox(color: color ?? Colors.red),
    ),
  );
}

class _DragStateProbe extends StatelessWidget {
  const _DragStateProbe({required this.sink, required this.child});

  final ValueNotifier<bool> sink;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = GraphDrag.maybeOf(context);
    if (scope == null) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: scope.draggingInsideGraph,
      builder: (_, v, _) {
        if (sink.value != v) {
          sink.value = v;
        }
        return child;
      },
    );
  }
}
