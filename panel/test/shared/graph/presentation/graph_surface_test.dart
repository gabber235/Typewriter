import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a replaced edge repaints in its new place and colour; a "
      "removed edge is no longer painted", (tester) async {
    const red = GraphEdge(
      id: "edge",
      source: GraphIdentifier("source"),
      target: GraphIdentifier("target"),
      color: Colors.red,
    );
    final elements = [graphNode("source"), graphNode("target", x: 4)];
    final data = ValueNotifier(
      GraphData(cellSize: 50, elements: elements, edges: [red]),
    );
    addTearDown(data.dispose);
    final panel = await tester.pumpGraphData(data);

    expect(
      panel.graph.paint().lines.map((line) => line.color.toARGB32()).toSet(),
      {Colors.red.toARGB32()},
    );

    data.value = GraphData(
      cellSize: 50,
      elements: elements,
      edges: const [
        GraphEdge(
          id: "edge",
          source: GraphIdentifier("source"),
          target: GraphIdentifier("target"),
          color: Colors.blue,
          sourceSide: EdgeSide.bottom,
          targetSide: EdgeSide.bottom,
        ),
      ],
    );
    await tester.pump();

    final replaced = panel.graph.paint().lines;
    expect(replaced.map((line) => line.color.toARGB32()).toSet(), {
      Colors.blue.toARGB32(),
    });
    expect(replaced.first.start, const Offset(50, 100));

    data.value = GraphData(cellSize: 50, elements: elements, edges: const []);
    await tester.pump();

    expect(panel.graph.paint().lines, isEmpty);
  });

  testWidgets("an edge is an opaque rounded arrow from source to target", (
    tester,
  ) async {
    final data = ValueNotifier(
      GraphData(
        cellSize: 50,
        elements: [graphNode("source"), graphNode("target", x: 4)],
        edges: const [
          GraphEdge(
            id: "edge",
            source: GraphIdentifier("source"),
            target: GraphIdentifier("target"),
            color: Color(0x33F44336),
          ),
        ],
      ),
    );
    addTearDown(data.dispose);
    final panel = await tester.pumpGraphData(data);

    final [shaft, ...head] = panel.graph.paint().lines;

    // The shaft leaves the source's right side and stops short of the
    // target's left side, so the tip stays visible beside the target.
    expect(shaft.start, const Offset(100, 50));
    expect(shaft.end.dy, 50);
    expect(shaft.end.dx, inExclusiveRange(150, 200));
    // Two strokes leave the tip back towards the source, one on each side.
    expect(head, hasLength(2));
    for (final stroke in head) {
      expect(stroke.start, shaft.end);
      expect(stroke.end.dx, lessThan(shaft.end.dx));
    }
    expect(head.map((stroke) => (stroke.end.dy - 50).sign).toSet(), {-1, 1});
    for (final line in [shaft, ...head]) {
      expect(line.cap, StrokeCap.round);
      expect(line.color.a, 1);
    }
  });

  testWidgets("a reordered node keeps its state; a removed node drops it", (
    tester,
  ) async {
    var nextToken = 0;
    final disposed = <String>[];

    final data = ValueNotifier(
      GraphData(
        cellSize: 50,
        elements: [
          graphNode(
            "a",
            priority: 0,
            body: GraphIdentityProbe(
              id: "a",
              token: ++nextToken,
              onDispose: disposed.add,
            ),
          ),
          graphNode(
            "b",
            priority: 1,
            body: GraphIdentityProbe(
              id: "b",
              token: ++nextToken,
              onDispose: disposed.add,
            ),
          ),
        ],
        edges: const [],
      ),
    );
    addTearDown(data.dispose);
    await tester.pumpGraphData(data);
    expect(find.text("a:1"), findsOneWidget);
    expect(find.text("b:2"), findsOneWidget);

    data.value = GraphData(
      cellSize: 50,
      elements: [
        graphNode(
          "b",
          priority: 0,
          body: GraphIdentityProbe(
            id: "b",
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        ),
        graphNode(
          "a",
          priority: 1,
          body: GraphIdentityProbe(
            id: "a",
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        ),
      ],
      edges: const [],
    );
    await tester.pump();
    expect(find.text("a:1"), findsOneWidget);
    expect(find.text("b:2"), findsOneWidget);
    expect(disposed, isEmpty);

    data.value = GraphData(
      cellSize: 50,
      elements: [
        graphNode(
          "a",
          priority: 0,
          body: GraphIdentityProbe(
            id: "a",
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        ),
      ],
      edges: const [],
    );
    await tester.pump();
    expect(find.text("a:1"), findsOneWidget);
    expect(disposed, ["b"]);

    data.value = GraphData(
      cellSize: 50,
      elements: [
        graphNode(
          "a",
          priority: 0,
          body: GraphIdentityProbe(
            id: "a",
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        ),
        graphNode(
          "c",
          priority: 1,
          body: GraphIdentityProbe(
            id: "c",
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        ),
      ],
      edges: const [],
    );
    await tester.pump();
    expect(find.text("a:1"), findsOneWidget);
    expect(find.text("c:7"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a viewport animation running at unmount ends quietly", (
    tester,
  ) async {
    GraphViewportController? controller;
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: shown,
          builder: (_, shown, _) => !shown
              ? const SizedBox()
              : HookBuilder(
                  builder: (context) {
                    controller = useGraphViewportController(
                      tickerProvider: useSingleTickerProvider(),
                      initialTransform: Matrix4.identity(),
                    );
                    return const SizedBox();
                  },
                ),
        ),
      ),
    );

    controller!.zoomAt(Offset.zero, 1.2);
    await tester.pump(const Duration(milliseconds: 20));
    shown.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets("zooming out thins and fades the dot grid instead of "
      "crowding it", (tester) async {
    final focus = FocusNode(debugLabel: "Node");
    addTearDown(focus.dispose);
    final data = ValueNotifier(
      GraphData(
        cellSize: 50,
        elements: [graphNode("Node", focusNode: focus)],
        edges: const [],
      ),
    );
    addTearDown(data.dispose);
    final panel = await tester.pumpGraphData(data);
    focus.requestFocus();
    await panel.settle();
    final width = panel.graph.rectOf("Node").width;

    // At most twice the 32 dots across the grid keeps before thinning, plus
    // the edge rows, in each direction.
    const crowded = 66 * 66;
    var faded = false;
    while (panel.graph.rectOf("Node").width > width * Graph.kGraphMinScale) {
      final dots = panel.graph.paint().circles;
      expect(dots, isNotEmpty);
      expect(dots.length, lessThanOrEqualTo(crowded));
      faded |= dots.map((dot) => dot.color.a).toSet().length > 1;
      final before = panel.graph.rectOf("Node").width;
      await panel.press(LogicalKeyboardKey.minus);
      if (panel.graph.rectOf("Node").width >= before) break;
    }

    expect(
      panel.graph.rectOf("Node").width,
      closeTo(width * Graph.kGraphMinScale, 1),
    );
    expect(panel.graph.paint().circles.length, lessThanOrEqualTo(crowded));
    expect(faded, isTrue, reason: "dots between two densities fade out");
  });
}
