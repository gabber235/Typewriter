import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
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
