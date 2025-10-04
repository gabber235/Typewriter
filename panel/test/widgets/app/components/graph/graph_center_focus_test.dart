import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_intents.dart";

import "../../../../test_utils.dart";

void main() {
  setupMocks();

  group("Graph - center focused child", () {
    testWidgets("centers the focused element at scale 1.0", (tester) async {
      final focusNodes = <String, FocusNode>{
        "a": FocusNode(debugLabel: "a"),
        "b": FocusNode(debugLabel: "b"),
        "target": FocusNode(debugLabel: "target"),
      };

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("a"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) =>
                _focusBox(id: "a", focusNode: focusNodes["a"]!),
          ),
          GraphElement(
            id: const GraphIdentifier("b"),
            x: 6,
            y: 0,
            width: 3,
            height: 2,
            builder: (context) =>
                _focusBox(id: "b", focusNode: focusNodes["b"]!),
          ),
          GraphElement(
            id: const GraphIdentifier("target"),
            x: 10,
            y: 0,
            width: 4,
            height: 3,
            builder: (context) =>
                _focusBox(id: "target", focusNode: focusNodes["target"]!),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(width: 1000, height: 700, child: Graph(data: data)),
        ),
        settle: true,
      );

      focusNodes["target"]!.requestFocus();
      await tester.pump();
      Actions.invoke(
        tester.element(find.byKey(const ValueKey("el-target"))),
        const GraphCenterFocusedIntent(),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final viewerCenter = tester.getCenter(find.byType(InteractiveViewer));
      final targetCenter = tester.getCenter(
        find.byKey(const ValueKey("el-target")),
      );

      expect((targetCenter - viewerCenter).dx.abs(), lessThanOrEqualTo(4));
      expect((targetCenter - viewerCenter).dy.abs(), lessThanOrEqualTo(4));
    });

    testWidgets("centers the focused element after zooming in (scale > 1.0)", (
      tester,
    ) async {
      final focusNodes = <String, FocusNode>{
        "other": FocusNode(debugLabel: "other"),
        "target": FocusNode(debugLabel: "target"),
      };

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("other"),
            x: 0,
            y: 0,
            width: 2,
            height: 2,
            builder: (context) =>
                _focusBox(id: "other", focusNode: focusNodes["other"]!),
          ),
          GraphElement(
            id: const GraphIdentifier("target"),
            x: 8,
            y: 0,
            width: 4,
            height: 3,
            builder: (context) =>
                _focusBox(id: "target", focusNode: focusNodes["target"]!),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(width: 1000, height: 700, child: Graph(data: data)),
        ),
        settle: true,
      );

      final viewerFinder = find.byType(InteractiveViewer);
      final viewerCenter = tester.getCenter(viewerFinder);

      final g1 = await tester.startGesture(viewerCenter - const Offset(80, 0));
      await tester.pump();
      final g2 = await tester.startGesture(
        viewerCenter + const Offset(80, 0),
        pointer: 11,
      );
      await tester.pump();

      await g1.moveBy(const Offset(-60, 0));
      await g2.moveBy(const Offset(60, 0));
      await tester.pump();

      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();

      focusNodes["other"]!.requestFocus();
      await tester.pumpAndSettle();

      focusNodes["target"]!.requestFocus();
      await tester.pump();
      Actions.invoke(
        tester.element(find.byKey(const ValueKey("el-target"))),
        const GraphCenterFocusedIntent(),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final viewerCenterAfter = tester.getCenter(viewerFinder);
      final targetCenter = tester.getCenter(
        find.byKey(const ValueKey("el-target")),
      );

      expect((targetCenter - viewerCenterAfter).dx.abs(), lessThanOrEqualTo(4));
      expect((targetCenter - viewerCenterAfter).dy.abs(), lessThanOrEqualTo(4));
    });

    testWidgets("centers the focused element after zooming out (scale < 1.0)", (
      tester,
    ) async {
      final focusNodes = <String, FocusNode>{
        "other": FocusNode(debugLabel: "other"),
        "target": FocusNode(debugLabel: "target"),
      };

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("other"),
            x: 0,
            y: 0,
            width: 3,
            height: 3,
            builder: (context) =>
                _focusBox(id: "other", focusNode: focusNodes["other"]!),
          ),
          GraphElement(
            id: const GraphIdentifier("target"),
            x: 4,
            y: 0,
            width: 4,
            height: 4,
            builder: (context) =>
                _focusBox(id: "target", focusNode: focusNodes["target"]!),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(width: 1000, height: 700, child: Graph(data: data)),
        ),
        settle: true,
      );

      final viewerFinder = find.byType(InteractiveViewer);
      final viewerCenter = tester.getCenter(viewerFinder);

      final g1 = await tester.startGesture(viewerCenter - const Offset(120, 0));
      await tester.pump();
      final g2 = await tester.startGesture(
        viewerCenter + const Offset(120, 0),
        pointer: 21,
      );
      await tester.pump();

      await g1.moveBy(const Offset(90, 0));
      await g2.moveBy(const Offset(-90, 0));
      await tester.pump();

      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();

      focusNodes["other"]!.requestFocus();
      await tester.pumpAndSettle();

      focusNodes["target"]!.requestFocus();
      await tester.pump();
      Actions.invoke(
        tester.element(find.byKey(const ValueKey("el-target"))),
        const GraphCenterFocusedIntent(),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final viewerCenterAfter = tester.getCenter(viewerFinder);
      final targetCenter = tester.getCenter(
        find.byKey(const ValueKey("el-target")),
      );

      expect((targetCenter - viewerCenterAfter).dx.abs(), lessThanOrEqualTo(4));
      expect((targetCenter - viewerCenterAfter).dy.abs(), lessThanOrEqualTo(4));
    });

    testWidgets("ignores focus changes outside of the graph", (tester) async {
      final focusNodes = <String, FocusNode>{
        "inside": FocusNode(debugLabel: "inside"),
        "outside1": FocusNode(debugLabel: "outside1"),
        "outside2": FocusNode(debugLabel: "outside2"),
      };

      final data = GraphData(
        cellSize: 50,
        elements: [
          GraphElement(
            id: const GraphIdentifier("inside"),
            x: 2,
            y: 1,
            width: 3,
            height: 2,
            builder: (context) =>
                _focusBox(id: "inside", focusNode: focusNodes["inside"]!),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1200,
            height: 700,
            child: Row(
              children: [
                Expanded(child: Graph(data: data)),
                SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: _focusBox(
                          id: "outside1",
                          focusNode: focusNodes["outside1"]!,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: _focusBox(
                          id: "outside2",
                          focusNode: focusNodes["outside2"]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        settle: true,
      );

      final viewerFinder = find.byType(InteractiveViewer);
      final insideFinder = find.byKey(const ValueKey("el-inside"));

      final viewerCenterBefore = tester.getCenter(viewerFinder);
      final insideCenterBefore = tester.getCenter(insideFinder);

      focusNodes["outside1"]!.requestFocus();
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final viewerCenterAfter1 = tester.getCenter(viewerFinder);
      final insideCenterAfter1 = tester.getCenter(insideFinder);

      final deltaBefore = insideCenterBefore - viewerCenterBefore;
      final deltaAfter1 = insideCenterAfter1 - viewerCenterAfter1;

      expect((deltaAfter1.dx - deltaBefore.dx).abs(), lessThanOrEqualTo(0.5));
      expect((deltaAfter1.dy - deltaBefore.dy).abs(), lessThanOrEqualTo(0.5));

      focusNodes["outside2"]!.requestFocus();
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final viewerCenterAfter2 = tester.getCenter(viewerFinder);
      final insideCenterAfter2 = tester.getCenter(insideFinder);
      final deltaAfter2 = insideCenterAfter2 - viewerCenterAfter2;

      expect((deltaAfter2.dx - deltaBefore.dx).abs(), lessThanOrEqualTo(0.5));
      expect((deltaAfter2.dy - deltaBefore.dy).abs(), lessThanOrEqualTo(0.5));
    });
  });
}

Widget _focusBox({required String id, required FocusNode focusNode}) {
  return Focus(
    focusNode: focusNode,
    child: RepaintBoundary(
      key: ValueKey("el-$id"),
      child: Container(
        color: Colors.primaries[max(id.hashCode % Colors.primaries.length, 0)],
      ),
    ),
  );
}
