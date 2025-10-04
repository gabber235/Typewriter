import "package:flutter/material.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";

class GraphElement implements Comparable<GraphElement> {
  const GraphElement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.builder,
    this.priority = 0,
  });

  final GraphIdentifier id;
  final int x;
  final int y;
  final int width;
  final int height;
  final int priority;
  final WidgetBuilder builder;

  bool inside(GraphElement other) {
    return x >= other.x &&
        x + width <= other.x + other.width &&
        y >= other.y &&
        y + height <= other.y + other.height;
  }

  GraphElement copyWith({
    GraphIdentifier? id,
    int? x,
    int? y,
    int? width,
    int? height,
    int? priority,
    WidgetBuilder? builder,
  }) => GraphElement(
    id: id ?? this.id,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    priority: priority ?? this.priority,
    builder: builder ?? this.builder,
  );

  @override
  String toString() =>
      "GraphElement(id: $id, x: $x, y: $y, width: $width, height: $height, priority: $priority)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return id == (other as GraphElement).id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(GraphElement other) {
    return priority.compareTo(other.priority);
  }
}
