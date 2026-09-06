import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "graph_element.freezed.dart";

@Freezed(equal: false, toStringOverride: false)
abstract class GraphElement
    with _$GraphElement
    implements Comparable<GraphElement> {
  const factory GraphElement({
    required GraphIdentifier id,
    required int x,
    required int y,
    required int width,
    required int height,
    required WidgetBuilder builder,
    @Default(0) int priority,
  }) = _GraphElement;

  const GraphElement._();

  bool inside(GraphElement other) {
    return x >= other.x &&
        x + width <= other.x + other.width &&
        y >= other.y &&
        y + height <= other.y + other.height;
  }

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
