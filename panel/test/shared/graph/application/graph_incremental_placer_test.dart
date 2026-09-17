import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const placer = GraphIncrementalPlacer();

  test("uses the preferred centered translation when it is free", () {
    final placed = placer.placeGroup(
      obstacles: const [],
      group: [_rect(0, 0, 4, 2)],
      anchor: const Offset(10, 8),
    );

    expect(placed, [_rect(8, 7, 4, 2)]);
  });

  test("searches clockwise through Manhattan rings", () {
    final placed = placer.placeGroup(
      obstacles: [_rect(0, 0, 1, 1)],
      group: [_rect(0, 0, 1, 1)],
      anchor: const Offset(0.5, 0.5),
    );

    expect(placed, [_rect(2, 0, 1, 1)]);
  });

  test("preserves relative coordinates for a group", () {
    final group = [_rect(0, 0, 3, 1), _rect(4, 2, 2, 1)];
    final placed = placer.placeGroup(
      obstacles: [_rect(0, 0, 3, 1), _rect(4, 2, 2, 1), _rect(7, 0, 4, 1)],
      group: group,
      anchor: const Offset(10, 1.5),
    );

    expect(placed, [_rect(7, 2, 3, 1), _rect(11, 4, 2, 1)]);
    expect(placed[1].x - placed[0].x, group[1].x - group[0].x);
    expect(placed[1].y - placed[0].y, group[1].y - group[0].y);
  });

  test("supports negative coordinates and variable dimensions", () {
    final obstacle = _rect(-4, -3, 5, 2);
    final placed = placer.placeGroup(
      obstacles: [obstacle],
      group: [_rect(0, 0, 2, 3)],
      anchor: const Offset(-1.5, -2),
    );

    expect(placed.single.overlaps(obstacle, gap: 1), isFalse);
  });

  test("empty group has no placement", () {
    expect(
      placer.placeGroup(
        obstacles: [_rect(0, 0, 1, 1)],
        group: const [],
        anchor: Offset.zero,
      ),
      isEmpty,
    );
  });

  test("center of mass preserves pixel area weighting", () {
    final center = graphCenterOfMass([
      _rect(0, 0, 4, 4),
      _rect(10, 0, 1, 1),
    ], cellSize: 10)!;

    expect(center.dx, lessThan(5));
    expect(center.dy, greaterThan(1));
  });

  test("center of mass is absent for an empty graph", () {
    expect(graphCenterOfMass(const [], cellSize: 10), isNull);
  });
}

GraphGridRect _rect(int x, int y, int width, int height) =>
    GraphGridRect(x: x, y: y, width: width, height: height);
