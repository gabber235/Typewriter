import "package:typewriter_panel/typewriter_panel.dart";

/// Payload shared by draggable graph sources and their target surface.
abstract class GraphDragData {
  const GraphDragData();

  GraphIdentifier get graphId;
}

/// Propagates drag lifecycle state to graph descendants.
///
/// [draggingInsideGraph] describes whether the current drag is over this graph;
/// [activeDragId] identifies the source node so its own drop region can remain
/// interactive while other node regions block the graph drop target.
class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.draggingInsideGraph,
    required super.child,
    this.activeDragId,
    super.key,
  });

  final ValueNotifier<bool> draggingInsideGraph;
  final ValueNotifier<GraphIdentifier?>? activeDragId;

  /// Marks [data] as the active drag source.
  void beginDrag(GraphDragData data) {
    activeDragId?.value = data.graphId;
    draggingInsideGraph.value = true;
  }

  /// Clears the active source and graph hover state.
  void endDrag() {
    activeDragId?.value = null;
    draggingInsideGraph.value = false;
  }

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) {
    return draggingInsideGraph != oldWidget.draggingInsideGraph ||
        activeDragId != oldWidget.activeDragId;
  }

  /// Returns the nearest graph drag scope, if one exists.
  static GraphDrag? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphDrag>();
  }

  /// Reads graph hover state without requiring a scope.
  static bool isDraggingInsideGraph(BuildContext context) {
    return maybeOf(context)?.draggingInsideGraph.value ?? false;
  }
}
