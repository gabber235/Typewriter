import "package:flutter/material.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";

abstract class GraphDragData {
  const GraphDragData();

  GraphIdentifier get graphId;
}

class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.draggingInsideGraph,
    required super.child,
    super.key,
  });

  final ValueNotifier<bool> draggingInsideGraph;

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) {
    return draggingInsideGraph != oldWidget.draggingInsideGraph;
  }

  static GraphDrag? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphDrag>();
  }

  static GraphDrag of(BuildContext context) {
    final graphDrag = context.dependOnInheritedWidgetOfExactType<GraphDrag>();
    assert(graphDrag != null, "GraphDrag was not a parent in the widget tree");
    return graphDrag!;
  }

  static bool isDraggingInsideGraph(BuildContext context) {
    return of(context).draggingInsideGraph.value;
  }
}
