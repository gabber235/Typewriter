import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract class GraphDragData {
  const GraphDragData();

  GraphIdentifier get graphId;
}

class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.draggingInsideGraph,
    required super.child,
    this.activeDragId,
    super.key,
  });

  final ValueNotifier<bool> draggingInsideGraph;
  final ValueNotifier<GraphIdentifier?>? activeDragId;

  void beginDrag(GraphDragData data) {
    activeDragId?.value = data.graphId;
    draggingInsideGraph.value = true;
  }

  void endDrag() {
    activeDragId?.value = null;
    draggingInsideGraph.value = false;
  }

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) {
    return draggingInsideGraph != oldWidget.draggingInsideGraph ||
        activeDragId != oldWidget.activeDragId;
  }

  static GraphDrag? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphDrag>();
  }

  static bool isDraggingInsideGraph(BuildContext context) {
    return maybeOf(context)?.draggingInsideGraph.value ?? false;
  }
}
