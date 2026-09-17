import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Places incoming graph rectangles without moving existing content.
///
/// The entire incoming group receives one integer translation, preserving its
/// internal geometry. Candidates follow deterministic Manhattan rings around
/// [anchor]. Search stops at the nearest guaranteed escape beyond the obstacle
/// bounds.
final class GraphIncrementalPlacer {
  const GraphIncrementalPlacer({this.gap = 1}) : assert(gap >= 0);

  /// Empty grid cells reserved between incoming and existing rectangles.
  final int gap;

  List<GraphGridRect> placeGroup({
    required Iterable<GraphGridRect> obstacles,
    required List<GraphGridRect> group,
    required Offset anchor,
  }) {
    if (group.isEmpty) return const [];
    final obstacleList = obstacles.toList(growable: false);
    final groupBounds = group.graphBounds!;
    final preferred = (
      x: (anchor.dx - groupBounds.center.dx).round(),
      y: (anchor.dy - groupBounds.center.dy).round(),
    );
    if (obstacleList.isEmpty) {
      return _translate(group, preferred.x, preferred.y);
    }

    final obstacleBounds = obstacleList.graphBounds!;
    final escapes = [
      (x: obstacleBounds.right + gap - groupBounds.x, y: preferred.y),
      (x: preferred.x, y: obstacleBounds.bottom + gap - groupBounds.y),
      (x: obstacleBounds.x - gap - groupBounds.right, y: preferred.y),
      (x: preferred.x, y: obstacleBounds.y - gap - groupBounds.bottom),
    ];
    final limit = escapes
        .map(
          (escape) =>
              (escape.x - preferred.x).abs() + (escape.y - preferred.y).abs(),
        )
        .reduce((left, right) => left < right ? left : right);

    for (var distance = 0; distance <= limit; distance++) {
      for (final offset in _diamond(distance)) {
        final dx = preferred.x + offset.x;
        final dy = preferred.y + offset.y;
        if (!_isValid(group, obstacleList, dx, dy)) continue;
        return _translate(group, dx, dy);
      }
    }
    throw StateError("The graph placement escape bound was not valid");
  }

  bool _isValid(
    List<GraphGridRect> group,
    List<GraphGridRect> obstacles,
    int dx,
    int dy,
  ) => group.every(
    (rect) => obstacles.every(
      (obstacle) => !rect.translate(dx, dy).overlaps(obstacle, gap: gap),
    ),
  );
}

List<GraphGridRect> _translate(List<GraphGridRect> group, int dx, int dy) => [
  for (final rect in group) rect.translate(dx, dy),
];

Iterable<({int x, int y})> _diamond(int distance) sync* {
  if (distance == 0) {
    yield (x: 0, y: 0);
    return;
  }
  for (var index = 0; index < distance; index++) {
    yield (x: distance - index, y: index);
  }
  for (var index = 0; index < distance; index++) {
    yield (x: -index, y: distance - index);
  }
  for (var index = 0; index < distance; index++) {
    yield (x: -distance + index, y: -index);
  }
  for (var index = 0; index < distance; index++) {
    yield (x: index, y: -distance + index);
  }
}
