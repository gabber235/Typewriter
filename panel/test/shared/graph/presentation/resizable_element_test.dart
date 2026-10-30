import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _id = GraphIdentifier("Body");
const _cell = 40.0;

/// The device a mouse gesture of a widget test reports.
const _mouse = 1;

/// An element of 2 by 3 cells.
final _element = GraphElement(
  id: _id,
  x: 0,
  y: 0,
  width: 2,
  height: 3,
  builder: (_) => const SizedBox(),
);

final _size = Size(_element.width * _cell, _element.height * _cell);

void main() {
  testWidgets("shows its element at the element's size with a resize handle", (
    tester,
  ) async {
    final panel = await tester.pumpResizable(
      element: _element,
      cellSize: _cell,
      child: SizedBox.fromSize(size: _size, child: const GraphNode("Body")),
    );

    expect(panel.graph.rectOf("Body").size, _size);
    expect(panel.graph.resizeHandle, findsOneWidget);
  });

  testWidgets("dragging the bottom right corner resizes by whole cells", (
    tester,
  ) async {
    final ends = <(GraphIdentifier, int, int)>[];
    final panel = await tester.pumpResizable(
      element: _element,
      cellSize: _cell,
      child: SizedBox.fromSize(size: _size, child: const GraphNode("Body")),
      onResizeStart: (_, _, _) {},
      onResizeUpdate: (_, _, _) {},
      onResizeEnd: (id, width, height) => ends.add((id, width, height)),
    );

    await panel.graph.drag(
      "Body",
      const Offset(_cell * 4, _cell * 2),
      at: _size.bottomRight(Offset.zero) - const Offset(2, 2),
    );

    expect(ends, [(_id, 6, 5)]);
  });

  testWidgets("a resize reports its start, growing previews and its end", (
    tester,
  ) async {
    final starts = <(GraphIdentifier, int, int)>[];
    final updates = <(GraphIdentifier, int, int)>[];
    final ends = <(GraphIdentifier, int, int)>[];
    final panel = await tester.pumpResizable(
      element: _element,
      cellSize: _cell,
      child: SizedBox.fromSize(size: _size, child: const GraphNode("Body")),
      onResizeStart: (id, width, height) => starts.add((id, width, height)),
      onResizeUpdate: (id, width, height) => updates.add((id, width, height)),
      onResizeEnd: (id, width, height) => ends.add((id, width, height)),
    );

    await tester.drag(
      panel.graph.resizeHandle,
      const Offset(_cell * 4, _cell * 2),
    );
    await panel.settle();

    expect(starts, [(_id, 2, 3)]);
    expect(updates, isNotEmpty);
    var (_, lastWidth, lastHeight) = starts.single;
    for (final (id, width, height) in updates) {
      expect(id, _id);
      expect(width, greaterThanOrEqualTo(lastWidth));
      expect(height, greaterThanOrEqualTo(lastHeight));
      (lastWidth, lastHeight) = (width, height);
    }
    expect(ends, [(_id, 6, 5)]);
  });

  testWidgets("an element never shrinks below one cell", (tester) async {
    final updates = <(GraphIdentifier, int, int)>[];
    final ends = <(GraphIdentifier, int, int)>[];
    final panel = await tester.pumpResizable(
      element: _element,
      cellSize: _cell,
      child: SizedBox.fromSize(size: _size, child: const GraphNode("Body")),
      onResizeStart: (_, _, _) {},
      onResizeUpdate: (id, width, height) => updates.add((id, width, height)),
      onResizeEnd: (id, width, height) => ends.add((id, width, height)),
    );

    await tester.drag(
      panel.graph.resizeHandle,
      const Offset(-_cell * 1000, -_cell * 1000),
    );
    await panel.settle();

    for (final (_, width, height) in updates) {
      expect(width, greaterThanOrEqualTo(1));
      expect(height, greaterThanOrEqualTo(1));
    }
    expect(ends, [(_id, 1, 1)]);
  });

  testWidgets("a cancelled resize commits nothing and releases the cursor", (
    tester,
  ) async {
    var updates = 0;
    var ends = 0;
    var cancels = 0;
    final panel = await tester.pumpResizable(
      element: _element,
      cellSize: _cell,
      child: SizedBox.fromSize(size: _size, child: const GraphNode("Body")),
      onResizeStart: (_, _, _) {},
      onResizeUpdate: (_, _, _) => updates++,
      onResizeEnd: (_, _, _) => ends++,
      onResizeCancel: () => cancels++,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(panel.graph.resizeHandle),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(_cell, _cell));
    await tester.pump();
    expect(updates, greaterThan(0));
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(_mouse),
      SystemMouseCursors.grabbing,
    );

    await gesture.cancel();
    await panel.settle();

    expect(ends, 0);
    expect(cancels, 1);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(_mouse),
      isNot(SystemMouseCursors.grabbing),
    );
  });
}
