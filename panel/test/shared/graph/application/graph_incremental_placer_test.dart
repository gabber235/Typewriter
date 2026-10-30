import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const placer = GraphIncrementalPlacer();

  test("uses the preferred centered translation when it is free", () {
    final placed = placer.placeGroup(
      obstacles: const [],
      group: [GraphGridRect(x: 0, y: 0, width: 4, height: 2)],
      anchor: const Offset(10, 8),
    );

    expect(placed, [GraphGridRect(x: 8, y: 7, width: 4, height: 2)]);
  });

  test("searches clockwise through Manhattan rings", () {
    final placed = placer.placeGroup(
      obstacles: [GraphGridRect(x: 0, y: 0, width: 1, height: 1)],
      group: [GraphGridRect(x: 0, y: 0, width: 1, height: 1)],
      anchor: const Offset(0.5, 0.5),
    );

    expect(placed, [GraphGridRect(x: 2, y: 0, width: 1, height: 1)]);
  });

  test("preserves relative coordinates for a group", () {
    final group = [
      GraphGridRect(x: 0, y: 0, width: 3, height: 1),
      GraphGridRect(x: 4, y: 2, width: 2, height: 1),
    ];
    final placed = placer.placeGroup(
      obstacles: [
        GraphGridRect(x: 0, y: 0, width: 3, height: 1),
        GraphGridRect(x: 4, y: 2, width: 2, height: 1),
        GraphGridRect(x: 7, y: 0, width: 4, height: 1),
      ],
      group: group,
      anchor: const Offset(10, 1.5),
    );

    expect(placed, [
      GraphGridRect(x: 7, y: 2, width: 3, height: 1),
      GraphGridRect(x: 11, y: 4, width: 2, height: 1),
    ]);
    expect(placed[1].x - placed[0].x, group[1].x - group[0].x);
    expect(placed[1].y - placed[0].y, group[1].y - group[0].y);
  });

  test("supports negative coordinates and variable dimensions", () {
    final obstacle = GraphGridRect(x: -4, y: -3, width: 5, height: 2);
    final placed = placer.placeGroup(
      obstacles: [obstacle],
      group: [GraphGridRect(x: 0, y: 0, width: 2, height: 3)],
      anchor: const Offset(-1.5, -2),
    );

    expect(placed.single.overlaps(obstacle, gap: 1), isFalse);
  });

  test("keeps placement inside each directional region", () {
    final cases = [
      (
        const GraphPlacementRegion.leftOf(0),
        (GraphGridRect rect) => rect.right <= 0,
      ),
      (
        const GraphPlacementRegion.rightOf(8),
        (GraphGridRect rect) => rect.x >= 8,
      ),
      (
        const GraphPlacementRegion.above(0),
        (GraphGridRect rect) => rect.bottom <= 0,
      ),
      (
        const GraphPlacementRegion.below(6),
        (GraphGridRect rect) => rect.y >= 6,
      ),
    ];

    for (final (region, isAllowed) in cases) {
      final placed = placer.placeGroup(
        obstacles: [GraphGridRect(x: -8, y: -8, width: 16, height: 14)],
        group: [GraphGridRect(x: 0, y: 0, width: 4, height: 2)],
        anchor: Offset.zero,
        allowedRegion: region,
      );

      expect(isAllowed(placed.single), isTrue);
      expect(
        placed.single.overlaps(
          GraphGridRect(x: -8, y: -8, width: 16, height: 14),
          gap: 1,
        ),
        isFalse,
      );
    }
  });

  test("uses a valid directional escape bound through dense obstacles", () {
    final placed = placer.placeGroup(
      obstacles: [
        for (var y = -10; y <= 10; y += 2)
          GraphGridRect(x: 4, y: y, width: 4, height: 1),
      ],
      group: [GraphGridRect(x: 0, y: 0, width: 4, height: 1)],
      anchor: const Offset(6, 0),
      allowedRegion: const GraphPlacementRegion.rightOf(4),
    );

    expect(placed.single.x, greaterThanOrEqualTo(9));
  });

  test("empty group has no placement", () {
    expect(
      placer.placeGroup(
        obstacles: [GraphGridRect(x: 0, y: 0, width: 1, height: 1)],
        group: const [],
        anchor: Offset.zero,
      ),
      isEmpty,
    );
  });

  test("center of mass preserves pixel area weighting", () {
    final center = graphCenterOfMass([
      GraphGridRect(x: 0, y: 0, width: 4, height: 4),
      GraphGridRect(x: 10, y: 0, width: 1, height: 1),
    ], cellSize: 10)!;

    expect(center.dx, lessThan(5));
    expect(center.dy, greaterThan(1));
  });

  test("center of mass is absent for an empty graph", () {
    expect(graphCenterOfMass(const [], cellSize: 10), isNull);
  });
}
