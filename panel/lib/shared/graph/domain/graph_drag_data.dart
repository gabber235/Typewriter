import "package:typewriter_panel/typewriter_panel.dart";

/// Payload shared by draggable graph sources and their target surface.
abstract class GraphDragData {
  const GraphDragData();
  GraphIdentifier get graphId;
}
