import "dart:math" as math;

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
    GraphPlacementRegion? allowedRegion,
  }) {
    if (group.isEmpty) return const [];
    final obstacleList = obstacles.toList(growable: false);
    final groupBounds = group.graphBounds!;
    final preferred =
        allowedRegion?.clampTranslation(groupBounds, (
          x: (anchor.dx - groupBounds.center.dx).round(),
          y: (anchor.dy - groupBounds.center.dy).round(),
        )) ??
        (
          x: (anchor.dx - groupBounds.center.dx).round(),
          y: (anchor.dy - groupBounds.center.dy).round(),
        );
    if (obstacleList.isEmpty) {
      return _translate(group, preferred.x, preferred.y);
    }

    final obstacleBounds = obstacleList.graphBounds!;
    final escapes = allowedRegion == null
        ? [
            (x: obstacleBounds.right + gap - groupBounds.x, y: preferred.y),
            (x: preferred.x, y: obstacleBounds.bottom + gap - groupBounds.y),
            (x: obstacleBounds.x - gap - groupBounds.right, y: preferred.y),
            (x: preferred.x, y: obstacleBounds.y - gap - groupBounds.bottom),
          ]
        : [
            allowedRegion.escapeTranslation(
              groupBounds,
              obstacleBounds,
              preferred,
              gap,
            ),
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
        if (allowedRegion != null &&
            !allowedRegion.allows(groupBounds.translate(dx, dy))) {
          continue;
        }
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

/// A directional half plane used for deterministic graph placement.
///
/// [boundary] is the outer edge of the fixed local graph. The incoming group
/// must remain fully on the selected side. Search still follows the placer
/// Manhattan rings, but its escape bound is derived in the allowed direction.
@immutable
final class GraphPlacementRegion {
  const GraphPlacementRegion.leftOf(this.boundary)
    : direction = GraphPlacementDirection.left;
  const GraphPlacementRegion.rightOf(this.boundary)
    : direction = GraphPlacementDirection.right;
  const GraphPlacementRegion.above(this.boundary)
    : direction = GraphPlacementDirection.above;
  const GraphPlacementRegion.below(this.boundary)
    : direction = GraphPlacementDirection.below;

  final GraphPlacementDirection direction;
  final int boundary;

  bool allows(GraphGridRect rect) => switch (direction) {
    GraphPlacementDirection.left => rect.right <= boundary,
    GraphPlacementDirection.right => rect.x >= boundary,
    GraphPlacementDirection.above => rect.bottom <= boundary,
    GraphPlacementDirection.below => rect.y >= boundary,
  };

  ({int x, int y}) clampTranslation(
    GraphGridRect group,
    ({int x, int y}) translation,
  ) => switch (direction) {
    GraphPlacementDirection.left => (
      x: math.min(translation.x, boundary - group.right),
      y: translation.y,
    ),
    GraphPlacementDirection.right => (
      x: math.max(translation.x, boundary - group.x),
      y: translation.y,
    ),
    GraphPlacementDirection.above => (
      x: translation.x,
      y: math.min(translation.y, boundary - group.bottom),
    ),
    GraphPlacementDirection.below => (
      x: translation.x,
      y: math.max(translation.y, boundary - group.y),
    ),
  };

  ({int x, int y}) escapeTranslation(
    GraphGridRect group,
    GraphGridRect obstacles,
    ({int x, int y}) preferred,
    int gap,
  ) => switch (direction) {
    GraphPlacementDirection.left => (
      x: math.min(preferred.x, obstacles.x - gap - group.right),
      y: preferred.y,
    ),
    GraphPlacementDirection.right => (
      x: math.max(preferred.x, obstacles.right + gap - group.x),
      y: preferred.y,
    ),
    GraphPlacementDirection.above => (
      x: preferred.x,
      y: math.min(preferred.y, obstacles.y - gap - group.bottom),
    ),
    GraphPlacementDirection.below => (
      x: preferred.x,
      y: math.max(preferred.y, obstacles.bottom + gap - group.y),
    ),
  };
}

enum GraphPlacementDirection { left, right, above, below }

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
