import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_element.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph_drag.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

/// Tests for the private slotted shell that composes the Graph render object
/// and a full-viewport DragTarget layer.
///
/// What we validate indirectly through the public Graph API:
/// - The DragTarget covers the current InteractiveViewer viewport, not the
///   graph's logical 1×1 render box, so drags are discoverable anywhere on
///   screen.
/// - Regular pointer interactions (e.g., taps) still reach graph children even
///   when the drag layer is mounted. This implies the hit test order favors the
///   graph child for non-drag gestures.
/// - When drag support is disabled (no onElementsDragged callback), the drag
///   layer is not mounted and the inherited drag state doesn't toggle.
///
/// Notes:
/// - We observe the drag-layer coverage and hit-testing by:
///   1) Starting a Draggable with GraphDragData and checking the GraphDrag
///      inherited notifier toggles when entering the viewport and resets after
///      accept.
///   2) Verifying that taps can focus a child below the drag layer.
///   3) Ensuring no drag state changes when the drag layer is disabled.
void main() {
  group("Graph - drag target shell (layout & hit testing)", () {
    testWidgets("drag target covers the viewport and accepts drags anywhere", (
      tester,
    ) async {
      const cell = 50.0;
      final dragInside = ValueNotifier<bool>(false);
      var acceptedCalls = 0;

      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 1,
            y: 1,
            width: 2,
            height: 2,
            builder: (_) => _DragStateProbe(
              sink: dragInside,
              child: _draggableNode("a", color: Colors.blue),
            ),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: data, onElementsDragged: (_) => acceptedCalls++),
          ),
        ),
        settle: true,
      );

      final aFinder = find.byKey(const ValueKey("el-a"));
      expect(aFinder, findsOneWidget);

      final start = tester.getCenter(aFinder);
      final moveTarget = tester.getTopLeft(aFinder) + const Offset(160, 120);

      final g = await tester.startGesture(start);
      await tester.pump();
      await g.moveTo(moveTarget);
      await tester.pump();

      expect(dragInside.value, isTrue);

      await g.up();
      await tester.pumpAndSettle();

      expect(acceptedCalls, greaterThanOrEqualTo(1));
      expect(dragInside.value, isFalse);
    });

    testWidgets("graph child still receives taps when drag layer is mounted", (
      tester,
    ) async {
      const cell = 50.0;
      final focusNode = FocusNode(debugLabel: "focusable");

      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("tap"),
            x: 2,
            y: 2,
            width: 3,
            height: 2,
            builder: (_) => _FocusableTapBox(
              key: const ValueKey("el-tap"),
              focusNode: focusNode,
            ),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,

            child: Graph(data: data, onElementsDragged: (_) {}),
          ),
        ),
        settle: true,
      );

      expect(focusNode.hasFocus, isFalse);

      await tester.tap(find.byKey(const ValueKey("el-tap")));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets(
      "when drag support is disabled, drag state remains false and no accept",
      (tester) async {
        const cell = 50.0;
        final dragInside = ValueNotifier<bool>(false);

        final data = GraphData(
          cellSize: cell,
          elements: [
            GraphElement(
              id: const GraphIdentifier("x"),
              x: 0,
              y: 0,
              width: 2,
              height: 2,
              builder: (_) => _DragStateProbe(
                sink: dragInside,
                child: _draggableNode("x", color: Colors.red),
              ),
            ),
          ],
          edges: const [],
        );

        await tester.pumpTestApp(
          child: Center(
            child: SizedBox(width: 600, height: 400, child: Graph(data: data)),
          ),
          settle: true,
        );

        final finder = find.byKey(const ValueKey("el-x"));
        expect(finder, findsOneWidget);

        final g = await tester.startGesture(tester.getCenter(finder));
        await tester.pump();
        await g.moveBy(const Offset(120, 60));
        await tester.pump();
        await g.up();
        await tester.pumpAndSettle();

        expect(dragInside.value, isFalse);
      },
    );
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
        child: ColoredBox(color: (color ?? Colors.blue).withValues(alpha: 0.8)),
      ),
    ),
    child: RepaintBoundary(
      key: ValueKey("el-$id"),
      child: ColoredBox(color: color ?? Colors.blue),
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
        // Mirror the current drag-inside state for assertions.
        if (sink.value != v) sink.value = v;
        return child;
      },
    );
  }
}

class _FocusableTapBox extends StatelessWidget {
  const _FocusableTapBox({required this.focusNode, super.key});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: focusNode.requestFocus,
        child: const ColoredBox(color: Colors.amber),
      ),
    );
  }
}
