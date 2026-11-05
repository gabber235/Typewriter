import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final MapEntry(key: zoom, value: step) in const {
    "at the starting zoom": 0.0,
    "after zooming in": 60.0,
    "after zooming out": -60.0,
  }.entries) {
    testWidgets("focus moves a node to the middle of the graph $zoom", (
      tester,
    ) async {
      final focus = {
        for (final label in ["Other", "Target"])
          label: FocusNode(debugLabel: label),
      };
      addTearDown(() {
        for (final node in focus.values) {
          node.dispose();
        }
      });
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          Center(
            child: SizedBox(
              width: 1000,
              height: 700,
              child: Graph(
                data: GraphData(
                  cellSize: 50,
                  elements: [
                    graphElement(
                      "Other",
                      width: 2,
                      height: 2,
                      focusNode: focus["Other"],
                    ),
                    graphElement(
                      "Target",
                      x: 10,
                      width: 4,
                      height: 3,
                      focusNode: focus["Target"],
                    ),
                  ],
                  edges: const [],
                ),
              ),
            ),
          ),
        ),
      );
      final graph = panel.graph;
      final size = graph.rectOf("Target").width;
      if (step != 0) {
        await graph.pinch(spread: 240, step: step, steps: 1);
        expect(
          graph.rectOf("Target").width,
          step > 0 ? greaterThan(size) : lessThan(size),
        );
      }

      focus["Other"]!.requestFocus();
      await panel.settle();
      expect(
        (graph.rectOf("Target").center - graph.center).distance,
        greaterThan(20),
        reason: "the target starts away from the middle",
      );

      focus["Target"]!.requestFocus();
      await panel.settle();

      expect(
        (graph.rectOf("Target").center - graph.center).distance,
        lessThanOrEqualTo(4),
      );
    });
  }

  testWidgets("focus outside the graph leaves its viewport alone", (
    tester,
  ) async {
    final focus = {
      for (final label in ["Inside", "Outside 1", "Outside 2"])
        label: FocusNode(debugLabel: label),
    };
    addTearDown(() {
      for (final node in focus.values) {
        node.dispose();
      }
    });
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 1200,
          height: 700,
          child: Row(
            children: [
              Expanded(
                child: Graph(
                  data: GraphData(
                    cellSize: 50,
                    elements: [
                      graphElement(
                        "Inside",
                        x: 2,
                        width: 3,
                        height: 2,
                        focusNode: focus["Inside"],
                      ),
                    ],
                    edges: const [],
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final label in ["Outside 1", "Outside 2"])
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: GraphNode(label, focusNode: focus[label]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final before = panel.graph.rectOf("Inside");

    for (final label in ["Outside 1", "Outside 2"]) {
      focus[label]!.requestFocus();
      await panel.settle();

      final after = panel.graph.rectOf("Inside");
      expect((after.center - before.center).distance, lessThan(0.5));
    }
  });
}
