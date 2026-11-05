import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";

/// A graph canvas, through the nodes the user reads on it and the gestures
/// that pan, zoom and drag them.
///
/// The graph is expected in the middle of the window, as a component location
/// places it.
final class GraphDriver extends ComponentDriver {
  GraphDriver(super.tester);

  /// The middle of the window, where the graph is.
  Offset get center {
    final view = tester.view;
    return (view.physicalSize / view.devicePixelRatio).center(Offset.zero);
  }

  /// The handle that resizes the element being shown; a test drags it.
  Finder get resizeHandle => labeled(ResizableElement.resizeHandleLabel);

  /// Whether a node reads as [label] on screen.
  bool hasNode(String label) => labeled(label).evaluate().isNotEmpty;

  /// Where the node [label] is on screen, after the viewport's zoom and pan.
  Rect rectOf(String label) => tester.getRect(_node(label));

  Finder _node(String label) {
    final node = labeled(label);
    if (node.evaluate().isEmpty) {
      throw TestFailure("The graph shows no node $label");
    }
    return node.first;
  }

  /// Puts a pointer down on the node [label] at [at], relative to its top
  /// left corner, or at its center.
  Future<TestGesture> grab(String label, {Offset? at, int? pointer}) async {
    final rect = rectOf(label);
    final gesture = await tester.startGesture(
      at == null ? rect.center : rect.topLeft + at,
      pointer: pointer,
    );
    await tester.pump();
    return gesture;
  }

  /// Drags the node [label] by [offset] and releases it.
  Future<void> drag(String label, Offset offset, {Offset? at}) async {
    final gesture = await grab(label, at: at);
    await gesture.moveBy(offset);
    await tester.pump();
    await gesture.up();
    await settle();
  }

  /// Pans the canvas by [offset], starting [from] a point of empty canvas
  /// relative to [center].
  Future<void> pan(Offset offset, {Offset from = Offset.zero}) async {
    await tester.dragFrom(center + from, offset);
    await settle();
  }

  /// Holds Shift and presses [key], the way a user starts a graph mode such as
  /// move (M) or resize (R), then lets go of Shift.
  Future<void> shiftPress(LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle();
  }

  /// What the graph surface paints now, recorded the way a canvas receives it.
  GraphPaint paint() {
    final canvas = _RecordingGraphCanvas();
    tester
        .renderObject<RenderGraphSurface>(find.byType(GraphSurface))
        .paint(TestRecordingPaintingContext(canvas), Offset.zero);
    return GraphPaint(lines: canvas.lines, circles: canvas.circles);
  }

  /// Pinches around [center] with two fingers [spread] apart, moving each
  /// finger [step] outward per frame until [done] holds or [steps] ran out.
  ///
  /// A positive [step] zooms in, a negative one zooms out.
  Future<void> pinch({
    required double spread,
    required double step,
    int steps = 80,
    bool Function()? done,
  }) async {
    final first = await tester.startGesture(
      center - Offset(spread / 2, 0),
      pointer: 71,
    );
    await tester.pump();
    final second = await tester.startGesture(
      center + Offset(spread / 2, 0),
      pointer: 72,
    );
    await tester.pump();
    for (var index = 0; index < steps; index++) {
      await first.moveBy(Offset(-step, 0));
      await second.moveBy(Offset(step, 0));
      await tester.pump();
      if (done?.call() ?? false) break;
    }
    await first.up();
    await second.up();
    await settle();
  }
}

/// One straight stroke the graph surface painted.
typedef GraphLine = ({Offset start, Offset end, Color color, StrokeCap cap});

/// One dot of the grid the graph surface painted.
typedef GraphDot = ({Offset center, Color color});

/// Everything the graph surface painted in one frame.
final class GraphPaint {
  const GraphPaint({required this.lines, required this.circles});

  /// Strokes in paint order: edge shafts and arrow heads.
  final List<GraphLine> lines;

  /// Grid dots in paint order.
  final List<GraphDot> circles;
}

final class _RecordingGraphCanvas extends TestRecordingCanvas {
  final lines = <GraphLine>[];
  final circles = <GraphDot>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add((start: p1, end: p2, color: paint.color, cap: paint.strokeCap));
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add((center: c, color: paint.color));
  }
}
