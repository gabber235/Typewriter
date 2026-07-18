import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";

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

  static bool isDraggingInsideGraph(BuildContext context) {
    return maybeOf(context)?.draggingInsideGraph.value ?? false;
  }
}
