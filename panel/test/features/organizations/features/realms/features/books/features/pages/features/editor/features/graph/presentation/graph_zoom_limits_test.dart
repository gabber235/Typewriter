import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_element.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

Widget _focusBox(FocusNode focusNode) {
  return Focus(focusNode: focusNode, child: const SizedBox.shrink());
}

GraphData _dataWithFocusableChild(FocusNode node) {
  return GraphData(
    cellSize: 50,
    elements: [
      GraphElement(
        id: const GraphIdentifier("focusable"),
        x: 0,
        y: 0,
        width: 2,
        height: 2,
        builder: (context) => _focusBox(node),
      ),
    ],
    edges: const [],
  );
}

double _currentScale(WidgetTester tester) {
  final viewer = tester.widget<InteractiveViewer>(
    find.byType(InteractiveViewer),
  );
  final ctrl = viewer.transformationController!;
  return ctrl.value.getMaxScaleOnAxis();
}

Future<void> _pumpGraphWithFocus(WidgetTester tester, FocusNode node) async {
  await tester.pumpTestApp(
    child: Center(
      child: SizedBox(
        width: 800,
        height: 600,
        child: Graph(data: _dataWithFocusableChild(node)),
      ),
    ),
    settle: true,
  );
  node.requestFocus();
  await tester.pumpAndSettle();
}

void main() {
  group("Graph zoom limits", () {
    testWidgets("InteractiveViewer min/max scale are configured and leading", (
      tester,
    ) async {
      final focusNode = FocusNode(debugLabel: "graph_focus");
      await _pumpGraphWithFocus(tester, focusNode);

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );

      expect(viewer.minScale, equals(Graph.kGraphMinScale));
      expect(viewer.maxScale, equals(Graph.kGraphMaxScale));

      final before = _currentScale(tester);
      expect(before, closeTo(1.0, 1e-6));
    });

    testWidgets("Zoom in clamps at max scale", (tester) async {
      final focusNode = FocusNode(debugLabel: "graph_focus");
      await _pumpGraphWithFocus(tester, focusNode);

      // Pinch zoom in to approach max scale without overshooting or crossing.
      final viewerFinder = find.byType(InteractiveViewer);
      final center = tester.getCenter(viewerFinder);
      final g1 = await tester.startGesture(center - const Offset(80, 0));
      await tester.pump();
      final g2 = await tester.startGesture(
        center + const Offset(80, 0),
        pointer: 11,
      );
      await tester.pump();
      const step = 8.0;
      for (var i = 0; i < 80; i++) {
        await g1.moveBy(const Offset(-step, 0));
        await g2.moveBy(const Offset(step, 0));
        await tester.pump();
        if (_currentScale(tester) >= Graph.kGraphMaxScale - 1e-3) {
          break;
        }
      }
      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();

      final scale = _currentScale(tester);
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );

      expect(scale, closeTo(Graph.kGraphMaxScale, 1e-6));
      expect(scale, closeTo(viewer.maxScale, 1e-6));
    });

    testWidgets("Zoom out clamps at min scale", (tester) async {
      final focusNode = FocusNode(debugLabel: "graph_focus");
      await _pumpGraphWithFocus(tester, focusNode);

      // Pinch zoom out to approach min scale without crossing pointers.
      final viewerFinder = find.byType(InteractiveViewer);
      final center = tester.getCenter(viewerFinder);
      final g1 = await tester.startGesture(center - const Offset(220, 0));
      await tester.pump();
      final g2 = await tester.startGesture(
        center + const Offset(220, 0),
        pointer: 21,
      );
      await tester.pump();
      const step = 8.0;
      for (var i = 0; i < 80; i++) {
        await g1.moveBy(const Offset(step, 0));
        await g2.moveBy(const Offset(-step, 0));
        await tester.pump();
        if (_currentScale(tester) <= Graph.kGraphMinScale + 1e-3) {
          break;
        }
      }
      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();

      final scale = _currentScale(tester);
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );

      expect(scale, closeTo(Graph.kGraphMinScale, 1e-6));
      expect(scale, closeTo(viewer.minScale, 1e-6));
    });
  });
}
