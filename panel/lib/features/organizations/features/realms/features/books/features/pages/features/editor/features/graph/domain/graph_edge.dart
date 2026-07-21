import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class GraphEdge {
  const GraphEdge({
    required this.id,
    required this.source,
    required this.target,
    required this.color,
    this.sourceSide = EdgeSide.right,
    this.targetSide = EdgeSide.left,
  });

  final String id;
  final GraphIdentifier source;
  final GraphIdentifier target;
  final Color color;
  final EdgeSide sourceSide;
  final EdgeSide targetSide;

  bool connectsTo(GraphElement element) {
    return source == element.id || target == element.id;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GraphEdge &&
        other.id == id &&
        other.source == source &&
        other.target == target &&
        other.color == color &&
        other.sourceSide == sourceSide &&
        other.targetSide == targetSide;
  }

  @override
  int get hashCode =>
      Object.hash(id, source, target, color, sourceSide, targetSide);
}
