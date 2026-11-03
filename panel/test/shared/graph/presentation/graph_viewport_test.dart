import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("reports grid center after layout and pan, then clears it", (
    tester,
  ) async {
    final centers = <Offset?>[];
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    final data = GraphData(
      cellSize: 50,
      elements: [
        GraphElement(
          id: const GraphIdentifier("Node"),
          x: 0,
          y: 0,
          width: 2,
          height: 2,
          builder: (_) => const GraphNode("Node"),
        ),
      ],
      edges: const [],
    );

    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: shown,
          builder: (_, shown, _) => SizedBox(
            width: 600,
            height: 400,
            child: shown
                ? Graph(data: data, onViewportCenterChanged: centers.add)
                : null,
          ),
        ),
      ),
    );

    final initial = centers.whereType<Offset>().last;
    expect(initial, const Offset(1, 1));

    await panel.graph.pan(const Offset(100, 0), from: const Offset(150, 0));

    final panned = centers.whereType<Offset>().last;
    expect(panned.dx, closeTo(initial.dx - 2, 0.001));
    expect(panned.dy, closeTo(initial.dy, 0.001));

    shown.value = false;
    await panel.settle();

    expect(centers.last, isNull);
  });

  testWidgets("a graph that narrows keeps the center of what it showed", (
    tester,
  ) async {
    final width = ValueNotifier(900.0);
    addTearDown(width.dispose);
    final centers = <Offset?>[];
    final data = GraphData(
      cellSize: 50,
      elements: [
        GraphElement(
          id: const GraphIdentifier("Node"),
          x: 2,
          y: 0,
          width: 1,
          height: 1,
          builder: (_) => const GraphNode("Node"),
        ),
      ],
      edges: const [],
    );

    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder(
            valueListenable: width,
            builder: (_, width, _) => SizedBox(
              width: width,
              height: 400,
              child: Graph(data: data, onViewportCenterChanged: centers.add),
            ),
          ),
        ),
      ),
    );
    final before = centers.whereType<Offset>().last;

    width.value = 340;
    await panel.settle();

    final after = centers.whereType<Offset>().last;
    expect(after.dx, closeTo(before.dx, 0.001));
    expect(after.dy, closeTo(before.dy, 0.001));
  });
}
