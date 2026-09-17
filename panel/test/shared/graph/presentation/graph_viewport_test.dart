import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("reports grid center after layout and pan, then clears it", (
    tester,
  ) async {
    final centers = <Offset?>[];
    final data = GraphData(
      cellSize: 50,
      elements: [
        GraphElement(
          id: const GraphIdentifier("node"),
          x: 0,
          y: 0,
          width: 2,
          height: 2,
          builder: (_) => const SizedBox.expand(),
        ),
      ],
      edges: const [],
    );

    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          width: 600,
          height: 400,
          child: Graph(data: data, onViewportCenterChanged: centers.add),
        ),
      ),
    );
    await tester.pump();

    final initial = centers.whereType<Offset>().last;
    expect(initial, const Offset(1, 1));

    await tester.drag(find.byType(InteractiveViewer), const Offset(100, 0));
    await tester.pumpAndSettle();

    final panned = centers.whereType<Offset>().last;
    expect(panned.dx, closeTo(initial.dx - 2, 0.001));
    expect(panned.dy, closeTo(initial.dy, 0.001));

    await tester.pumpTestApp(child: const SizedBox.shrink());

    expect(centers.last, isNull);
  });
}
