import "package:typewriter_panel/typewriter_panel.dart";

part "graph_element.freezed.dart";

/// Renderable node in a [GraphData] snapshot.
///
/// Coordinates and dimensions are expressed in grid cells. [builder] creates
/// the widget at the node's current placement. Equality is identity based on
/// [id], so a node can be looked up and selected independently of its widget.
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

  /// Whether this element is fully contained by [other] in grid coordinates.
  ///
  /// This is used when a drag begins on a containing element to include nested
  /// elements in the same move.
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
