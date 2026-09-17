import "package:flutter/widgets.dart";

/// Integer rectangle used by graph placement policies.
///
/// Coordinates and dimensions are expressed in grid cells. Dimensions are
/// validated at construction, so placement algorithms may assume positive
/// extents. [overlaps] can reserve empty cells around both rectangles.
@immutable
final class GraphGridRect {
  factory GraphGridRect({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0) {
      throw ArgumentError.value(width, "width", "Must be positive");
    }
    if (height <= 0) {
      throw ArgumentError.value(height, "height", "Must be positive");
    }
    return GraphGridRect._(x: x, y: y, width: width, height: height);
  }

  const GraphGridRect._({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
  Offset get center => Offset(x + width / 2, y + height / 2);

  GraphGridRect translate(int dx, int dy) =>
      GraphGridRect._(x: x + dx, y: y + dy, width: width, height: height);

  /// Whether this rectangle intersects [other] after reserving [gap] cells.
  bool overlaps(GraphGridRect other, {int gap = 0}) {
    if (gap < 0) {
      throw ArgumentError.value(gap, "gap", "Must not be negative");
    }
    return x - gap < other.right &&
        right + gap > other.x &&
        y - gap < other.bottom &&
        bottom + gap > other.y;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphGridRect &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => "GraphGridRect($x, $y, $width, $height)";
}

extension GraphGridRectCollection on Iterable<GraphGridRect> {
  /// Smallest rectangle containing every value, or null for empty input.
  GraphGridRect? get graphBounds {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    var left = iterator.current.x;
    var top = iterator.current.y;
    var right = iterator.current.right;
    var bottom = iterator.current.bottom;
    while (iterator.moveNext()) {
      final rect = iterator.current;
      if (rect.x < left) left = rect.x;
      if (rect.y < top) top = rect.y;
      if (rect.right > right) right = rect.right;
      if (rect.bottom > bottom) bottom = rect.bottom;
    }
    return GraphGridRect(
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
  }
}

/// Returns the area weighted center in grid coordinates.
///
/// [cellSize] converts cell area to the pixel area used by the existing graph
/// centering policy. Empty input has no center and returns null.
Offset? graphCenterOfMass(
  Iterable<GraphGridRect> rects, {
  required double cellSize,
}) {
  if (!cellSize.isFinite || cellSize <= 0) {
    throw ArgumentError.value(
      cellSize,
      "cellSize",
      "Must be finite and positive",
    );
  }
  final values = rects.toList(growable: false);
  if (values.isEmpty) return null;

  var totalMass = 0.0;
  var weightedX = 0.0;
  var weightedY = 0.0;
  for (final rect in values) {
    final pixelArea = rect.width * cellSize * rect.height * cellSize;
    final mass = 1.0 + pixelArea * 0.001;
    totalMass += mass;
    weightedX += rect.center.dx * mass;
    weightedY += rect.center.dy * mass;
  }
  return Offset(weightedX / totalMass, weightedY / totalMass);
}
