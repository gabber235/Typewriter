import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Starts the panel with one graph canvas in the middle of the window.
extension PumpGraph on WidgetTester {
  /// Pumps [graph] in a canvas of [size] as a component of the panel.
  Future<PanelDriver> pumpGraph(
    Graph graph, {
    Size size = const Size(800, 600),
  }) => pumpPanel(
    const [],
    at: PanelLocation.component(SizedBox.fromSize(size: size, child: graph)),
  );

  /// Pumps the graph of [data] in a canvas of [size]. The graph rebuilds
  /// whenever the test replaces [data]'s value, as its owner would rebuild it.
  Future<PanelDriver> pumpGraphData(
    ValueListenable<GraphData> data, {
    Size size = const Size(800, 600),
  }) => pumpPanel(
    const [],
    at: PanelLocation.component(
      SizedBox.fromSize(
        size: size,
        child: ValueListenableBuilder(
          valueListenable: data,
          builder: (_, data, _) => Graph(data: data),
        ),
      ),
    ),
  );

  /// Pumps [element] as a resizable element of [cellSize] pixels per cell,
  /// showing [child] as its body. Callbacks are optional; the handle is found
  /// by [ResizableElement.resizeHandleLabel].
  Future<PanelDriver> pumpResizable({
    required GraphElement element,
    required double cellSize,
    required Widget child,
    GraphResizeCallback? onResizeStart,
    GraphResizeCallback? onResizeUpdate,
    GraphResizeCallback? onResizeEnd,
    VoidCallback? onResizeCancel,
  }) => pumpPanel(
    const [],
    at: PanelLocation.component(
      ResizableElement(
        element: element,
        onResizeStart: onResizeStart,
        onResizeUpdate: onResizeUpdate,
        onResizeEnd: onResizeEnd,
        onResizeCancel: onResizeCancel,
        cellSize: cellSize,
        child: child,
      ),
    ),
  );
}
