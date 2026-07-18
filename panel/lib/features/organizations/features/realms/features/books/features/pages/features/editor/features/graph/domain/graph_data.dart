import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_edge.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_element.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";

class GraphData {
  GraphData({
    required this.cellSize,
    required this.elements,
    required this.edges,
  }) : keyedElements = Map.fromIterable(
         elements,
         key: (element) => element.id,
       ) {
    for (final edge in edges) {
      (elementsConnectedEdges[edge.source] ??= <GraphEdge>[]).add(edge);
      (elementsConnectedEdges[edge.target] ??= <GraphEdge>[]).add(edge);
    }
  }

  final double cellSize;
  final List<GraphElement> elements;
  final List<GraphEdge> edges;
  final Map<GraphIdentifier, GraphElement> keyedElements;
  final Map<GraphIdentifier, List<GraphEdge>> elementsConnectedEdges = {};

  GraphData offsetChildren({
    required Offset offset,
    required List<GraphIdentifier> ids,
  }) {
    if (offset == Offset.zero) return this;
    if (ids.isEmpty) return this;

    final dx = (offset.dx / cellSize).round();
    final dy = (offset.dy / cellSize).round();

    final newElements = elements.map((element) {
      if (!ids.contains(element.id)) {
        return element;
      }
      return element.copyWith(x: element.x + dx, y: element.y + dy);
    }).toList();
    return copyWith(elements: newElements);
  }

  GraphData resizeChild({(GraphIdentifier, int, int)? resize}) {
    if (resize == null) return this;
    final (id, width, height) = resize;
    final newElements = elements.map((element) {
      if (element.id != id) {
        return element;
      }
      return element.copyWith(width: width, height: height);
    }).toList();
    return copyWith(elements: newElements);
  }

  GraphData copyWith({
    double? cellSize,
    List<GraphElement>? elements,
    List<GraphEdge>? edges,
  }) => GraphData(
    cellSize: cellSize ?? this.cellSize,
    elements: elements ?? this.elements,
    edges: edges ?? this.edges,
  );

  @override
  String toString() => "GraphData(elements: $elements, edges: $edges)";
}
