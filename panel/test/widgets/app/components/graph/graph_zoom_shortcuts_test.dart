import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";

import "../../../../test_utils.dart";

Future<void> _pressKeys(
  WidgetTester tester, {
  required LogicalKeyboardKey trigger,
  LogicalKeyboardKey? modifier,
}) async {
  if (modifier != null) {
    await tester.sendKeyDownEvent(modifier);
  }
  await tester.sendKeyDownEvent(trigger);
  await tester.pump();
  await tester.sendKeyUpEvent(trigger);
  if (modifier != null) {
    await tester.sendKeyUpEvent(modifier);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _focusBox(FocusNode focusNode) {
  return Focus(focusNode: focusNode, child: const SizedBox.shrink());
}

void main() {
  GraphData dataWithFocusableChild(FocusNode node) {
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

  double currentScale(WidgetTester tester) {
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final ctrl = viewer.transformationController!;
    return ctrl.value.getMaxScaleOnAxis();
  }

  Future<void> pumpGraphWithFocus(WidgetTester tester, FocusNode node) async {
    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(data: dataWithFocusableChild(node)),
        ),
      ),
      settle: true,
    );
    node.requestFocus();
    await tester.pumpAndSettle();
  }

  testWidgets("Equal zooms in", (tester) async {
    final focusNode = FocusNode(debugLabel: "graph_focus");
    await pumpGraphWithFocus(tester, focusNode);

    final before = currentScale(tester);
    expect(before, closeTo(1.0, 1e-6));

    await _pressKeys(tester, trigger: LogicalKeyboardKey.equal);

    final after = currentScale(tester);
    expect(after, greaterThan(before));
  });

  testWidgets("Equal zooms in (unmodified)", (tester) async {
    final focusNode = FocusNode(debugLabel: "graph_focus");
    await pumpGraphWithFocus(tester, focusNode);

    final before = currentScale(tester);
    expect(before, closeTo(1.0, 1e-6));

    await _pressKeys(tester, trigger: LogicalKeyboardKey.equal);

    final after = currentScale(tester);
    expect(after, greaterThan(before));
  });

  testWidgets("Digit 0 resets zoom", (tester) async {
    final focusNode = FocusNode(debugLabel: "graph_focus");
    await pumpGraphWithFocus(tester, focusNode);

    await _pressKeys(tester, trigger: LogicalKeyboardKey.equal);
    final beforeReset = currentScale(tester);
    expect(beforeReset, greaterThan(1.0));

    await _pressKeys(tester, trigger: LogicalKeyboardKey.digit0);

    final afterReset = currentScale(tester);
    expect(afterReset, closeTo(1.0, 1e-6));
  });

  testWidgets("Digit 0 resets zoom (unmodified)", (tester) async {
    final focusNode = FocusNode(debugLabel: "graph_focus");
    await pumpGraphWithFocus(tester, focusNode);

    await _pressKeys(tester, trigger: LogicalKeyboardKey.equal);
    final beforeReset = currentScale(tester);
    expect(beforeReset, greaterThan(1.0));

    await _pressKeys(tester, trigger: LogicalKeyboardKey.digit0);

    final afterReset = currentScale(tester);
    expect(afterReset, closeTo(1.0, 1e-6));
  });
}
