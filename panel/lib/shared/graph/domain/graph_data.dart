import "package:typewriter_panel/typewriter_panel.dart";

class GraphData {
  factory GraphData({
    required double cellSize,
    required List<GraphElement> elements,
    required List<GraphEdge> edges,
  }) {
    if (!cellSize.isFinite || cellSize <= 0) {
      throw ArgumentError.value(
        cellSize,
        "cellSize",
        "Must be finite and positive",
      );
    }

    final immutableElements = List<GraphElement>.unmodifiable(elements);
    final immutableEdges = List<GraphEdge>.unmodifiable(edges);
    final keyedElements = <GraphIdentifier, GraphElement>{};
    for (final element in immutableElements) {
      if (element.id.id.trim().isEmpty) {
        throw ArgumentError.value(
          element.id,
          "elements",
          "Identifiers must not be empty",
        );
      }
      if (element.width <= 0 || element.height <= 0) {
        throw ArgumentError.value(
          element,
          "elements",
          "Dimensions must be positive",
        );
      }
      if (keyedElements.containsKey(element.id)) {
        throw ArgumentError.value(
          element.id,
          "elements",
          "Identifiers must be unique",
        );
      }
      keyedElements[element.id] = element;
    }

    final connectedEdges = <GraphIdentifier, List<GraphEdge>>{};
    final edgeIds = <String>{};
    for (final edge in immutableEdges) {
      if (edge.id.trim().isEmpty ||
          edge.source.id.trim().isEmpty ||
          edge.target.id.trim().isEmpty) {
        throw ArgumentError.value(
          edge,
          "edges",
          "Identifiers must not be empty",
        );
      }
      if (!edgeIds.add(edge.id)) {
        throw ArgumentError.value(
          edge.id,
          "edges",
          "Identifiers must be unique",
        );
      }
      (connectedEdges[edge.source] ??= []).add(edge);
      (connectedEdges[edge.target] ??= []).add(edge);
    }

    return GraphData._(
      cellSize: cellSize,
      elements: immutableElements,
      edges: immutableEdges,
      keyedElements: Map.unmodifiable(keyedElements),
      elementsConnectedEdges: Map.unmodifiable({
        for (final entry in connectedEdges.entries)
          entry.key: List<GraphEdge>.unmodifiable(entry.value),
      }),
    );
  }

  const GraphData._({
    required this.cellSize,
    required this.elements,
    required this.edges,
    required this.keyedElements,
    required this.elementsConnectedEdges,
  });

  final double cellSize;
  final List<GraphElement> elements;
  final List<GraphEdge> edges;
  final Map<GraphIdentifier, GraphElement> keyedElements;
  final Map<GraphIdentifier, List<GraphEdge>> elementsConnectedEdges;

  @override
  String toString() => "GraphData(elements: $elements, edges: $edges)";
}
