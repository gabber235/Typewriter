import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/graph_direction.dart";
import "package:typewriter_testkit/src/mocks/graph_layout.dart";

void main() {
  group("Graph Layout", () {
    // ============ DATA TYPES ============

    group("Point", () {
      test("stores x and y values correctly", () {
        const point = Point(5, 10);
        expect(point.x, equals(5));
        expect(point.y, equals(10));
      });

      test("supports generic types", () {
        const intPoint = Point<int>(1, 2);
        const doublePoint = Point<double>(1.5, 2.5);
        expect(intPoint.x, isA<int>());
        expect(doublePoint.x, isA<double>());
      });
    });

    group("GraphBounds", () {
      test("calculates dimensions correctly", () {
        const bounds = GraphBounds(2, 3, 8, 7);
        expect(bounds.width, equals(7));
        expect(bounds.height, equals(5));
      });

      test("detects overlaps correctly", () {
        const bounds1 = GraphBounds(0, 0, 5, 5);
        const bounds2 = GraphBounds(3, 3, 8, 8);
        const bounds3 = GraphBounds(10, 10, 15, 15);

        expect(bounds1.overlaps(bounds2, 0, 0), isTrue);
        expect(bounds1.overlaps(bounds3, 0, 0), isFalse);
        expect(bounds2.overlaps(bounds3, 0, 0), isFalse);
      });

      test("overlapsWith method works correctly", () {
        const bounds1 = GraphBounds(0, 0, 5, 5);
        const bounds2 = GraphBounds(3, 3, 8, 8);
        const bounds3 = GraphBounds(10, 10, 15, 15);

        expect(bounds1.overlapsWith(bounds2), isTrue);
        expect(bounds1.overlapsWith(bounds3), isFalse);
        expect(bounds2.overlapsWith(bounds3), isFalse);
      });

      test("offset method works correctly", () {
        const bounds = GraphBounds(0, 0, 5, 5);
        final offsetBounds = bounds.offset(10, 20);

        expect(offsetBounds.minX, equals(10));
        expect(offsetBounds.minY, equals(20));
        expect(offsetBounds.maxX, equals(15));
        expect(offsetBounds.maxY, equals(25));
      });
    });

    group("PlacementResult", () {
      test("stores values correctly", () {
        const placement = PlacementResult(1, 2, 3, 4);
        expect(placement.x, equals(1));
        expect(placement.y, equals(2));
        expect(placement.width, equals(3));
        expect(placement.height, equals(4));
      });

      test("offset method shifts x,y but keeps w,h", () {
        const placement = PlacementResult(10, 20, 3, 4);
        final offset = placement.offset(5, 10);

        expect(offset.x, equals(15));
        expect(offset.y, equals(30));
        expect(offset.width, equals(3));
        expect(offset.height, equals(4));
      });
    });

    group("GroupLayout", () {
      test("contains expected properties", () {
        final layers = [
          ["a", "b"],
          ["c"],
        ];
        final placements = {
          "a": const PlacementResult(0, 0, 3, 1),
          "b": const PlacementResult(0, 2, 3, 1),
          "c": const PlacementResult(5, 1, 3, 1),
        };
        const bounds = GraphBounds(0, 0, 8, 3);

        final layout = GroupLayout(layers, placements, bounds);

        expect(layout.layers, equals(layers));
        expect(layout.placements, equals(placements));
        expect(layout.bounds, equals(bounds));
      });
    });

    // ============ UTILITY FUNCTIONS ============

    group("generateGroupSizes", () {
      test("creates valid group splits", () {
        final sizes1 = generateGroupSizes(10);
        expect(sizes1.fold(0, (a, b) => a + b), equals(10));
        expect(sizes1.length, greaterThanOrEqualTo(1));
        expect(sizes1.length, lessThanOrEqualTo(5));
        expect(sizes1.every((size) => size > 0), isTrue);
      });

      test("returns single group for small counts", () {
        expect(generateGroupSizes(1), equals([1]));
        expect(generateGroupSizes(2), equals([2]));
        expect(generateGroupSizes(3), equals([3]));
      });
    });

    group("splitIntoGroups", () {
      test("correctly divides items", () {
        final items = ["a", "b", "c", "d", "e", "f"];
        final groups = splitIntoGroups(items, [2, 3, 1]);

        expect(groups.length, equals(3));
        expect(groups[0], equals(["a", "b"]));
        expect(groups[1], equals(["c", "d", "e"]));
        expect(groups[2], equals(["f"]));
      });
    });

    group("distributeIntoLayers", () {
      test("creates non-empty layers", () {
        final items = List.generate(6, (i) => "item_$i");
        final layers = distributeIntoLayers(items, 3);

        expect(layers.every((layer) => layer.isNotEmpty), isTrue);
        final totalItems = layers.fold(0, (sum, layer) => sum + layer.length);
        expect(totalItems, equals(6));
      });

      test("filters empty layers", () {
        final items = ["a"];
        final layers = distributeIntoLayers(items, 5);

        expect(layers.length, equals(1));
        expect(layers.first.length, equals(1));
      });
    });

    group("crossPoints", () {
      test("distributes points evenly", () {
        final points = crossPoints(3, 2, 20);
        expect(points.length, equals(3));

        for (final point in points) {
          expect(point, greaterThanOrEqualTo(0));
          expect(point, lessThanOrEqualTo(20));
        }
      });

      test("handles single item", () {
        final points = crossPoints(1, 3, 10);
        expect(points.length, equals(1));
        expect(points.first, greaterThanOrEqualTo(0));
        expect(points.first, lessThanOrEqualTo(10));
      });
    });

    group("findNonOverlappingPosition", () {
      test("finds valid positions", () {
        const existing1 = GraphBounds(0, 0, 5, 5);
        const existing2 = GraphBounds(10, 0, 15, 5);
        const newGraph = GraphBounds(0, 0, 3, 3);

        final position = findNonOverlappingPosition(newGraph, [
          existing1,
          existing2,
        ], GraphDirection.leftToRight);

        expect(position.x, greaterThanOrEqualTo(0));
        expect(position.y, greaterThanOrEqualTo(0));

        final offsetBounds = newGraph.offset(position.x, position.y);
        expect(offsetBounds.overlapsWith(existing1), isFalse);
        expect(offsetBounds.overlapsWith(existing2), isFalse);
      });

      test("handles empty existing graphs", () {
        const newGraph = GraphBounds(0, 0, 3, 3);
        final position = findNonOverlappingPosition(
          newGraph,
          [],
          GraphDirection.leftToRight,
        );

        expect(position.x, equals(0));
        expect(position.y, equals(0));
      });
    });

    // ============ CORE LAYOUT FUNCTIONS ============

    group("layoutLayers", () {
      test("returns empty map for empty layers", () {
        final result = layoutLayers<String>(
          layers: [],
          getId: (s) => s,
          direction: GraphDirection.leftToRight,
        );
        expect(result, isEmpty);
      });

      test("assigns placements to all items", () {
        final layers = [
          ["a", "b"],
          ["c"],
        ];
        final result = layoutLayers<String>(
          layers: layers,
          getId: (s) => s,
          direction: GraphDirection.leftToRight,
        );

        expect(result.keys.toSet(), equals({"a", "b", "c"}));
      });

      test("respects itemWidth and itemHeight", () {
        final layers = [
          ["item1"],
        ];
        final result = layoutLayers<String>(
          layers: layers,
          getId: (s) => s,
          direction: GraphDirection.leftToRight,
          itemWidth: 5,
          itemHeight: 2,
        );

        final placement = result["item1"]!;
        expect(placement.width, equals(5));
        expect(placement.height, equals(2));
      });

      test("handles leftToRight direction", () {
        final layers = [
          ["a"],
          ["b"],
        ];
        final result = layoutLayers<String>(
          layers: layers,
          getId: (s) => s,
          direction: GraphDirection.leftToRight,
        );

        expect(result["a"]!.x, lessThan(result["b"]!.x));
      });

      test("handles topToBottom direction", () {
        final layers = [
          ["a"],
          ["b"],
        ];
        final result = layoutLayers<String>(
          layers: layers,
          getId: (s) => s,
          direction: GraphDirection.topToBottom,
        );

        expect(result["a"]!.y, lessThan(result["b"]!.y));
      });
    });

    group("boundsFromPlacements", () {
      test("returns zero bounds for empty map", () {
        final bounds = boundsFromPlacements({});
        expect(bounds.minX, equals(0));
        expect(bounds.minY, equals(0));
        expect(bounds.maxX, equals(0));
        expect(bounds.maxY, equals(0));
      });

      test("calculates correct bounds", () {
        final placements = {
          "a": const PlacementResult(0, 0, 3, 1),
          "b": const PlacementResult(5, 2, 3, 1),
          "c": const PlacementResult(2, 4, 3, 1),
        };

        final bounds = boundsFromPlacements(placements);

        expect(bounds.minX, equals(0));
        expect(bounds.minY, equals(0));
        expect(bounds.maxX, equals(8));
        expect(bounds.maxY, equals(5));
      });
    });

    group("layoutSingleGroup", () {
      test("creates correct structure", () {
        final items = ["a", "b", "c"];
        final layout = layoutSingleGroup<String>(
          items: items,
          getId: (s) => s,
          direction: GraphDirection.leftToRight,
          organizeIntoLayers: (items) => [items],
        );

        expect(layout.layers, isNotEmpty);
        expect(layout.placements.length, equals(3));
        expect(layout.bounds.width, greaterThan(0));
        expect(layout.bounds.height, greaterThan(0));
      });
    });

    group("generateDynamicLayout", () {
      test("returns empty for empty items", () {
        final result = generateDynamicLayout<String>(
          items: [],
          getId: (s) => s,
          organizeIntoLayers: (items) => [items],
        );
        expect(result, isEmpty);
      });

      test("assigns placement to all items", () {
        final items = ["a", "b", "c", "d", "e"];
        final result = generateDynamicLayout<String>(
          items: items,
          getId: (s) => s,
          organizeIntoLayers: (items) => [items],
        );

        expect(result.keys.toSet(), equals(items.toSet()));
      });

      test("respects specified direction", () {
        final items = ["a", "b"];
        final result = generateDynamicLayout<String>(
          items: items,
          getId: (s) => s,
          organizeIntoLayers: (items) => [
            [items.first],
            [items.last],
          ],
          direction: GraphDirection.topToBottom,
        );

        expect(result["a"]!.y, lessThan(result["b"]!.y));
      });

      test("creates non-overlapping groups", () {
        final items = List.generate(20, (i) => "item_$i");
        final result = generateDynamicLayout<String>(
          items: items,
          getId: (s) => s,
          organizeIntoLayers: (items) => distributeIntoLayers(items, 3),
          direction: GraphDirection.leftToRight,
        );

        final placedBounds = result.values
            .map((p) => GraphBounds(p.x, p.y, p.x + p.width, p.y + p.height))
            .toList();

        for (int i = 0; i < placedBounds.length; i++) {
          for (int j = i + 1; j < placedBounds.length; j++) {
            expect(
              placedBounds[i].overlapsWith(placedBounds[j]),
              isFalse,
              reason: "Items should not overlap: $i and $j",
            );
          }
        }
      });

      test("handles custom item dimensions", () {
        final items = ["a", "b"];
        final result = generateDynamicLayout<String>(
          items: items,
          getId: (s) => s,
          organizeIntoLayers: (items) => [items],
          itemWidth: 10,
          itemHeight: 5,
        );

        for (final placement in result.values) {
          expect(placement.width, equals(10));
          expect(placement.height, equals(5));
        }
      });

      test("uses custom groupBy when provided", () {
        final items = ["a", "b", "c", "d", "e", "f"];

        List<List<String>> customGroupBy(List<String> items) {
          return [
            ["a", "b", "c"],
            ["d", "e", "f"],
          ];
        }

        final result = generateDynamicLayout<String>(
          items: items,
          getId: (s) => s,
          organizeIntoLayers: (List<String> items) =>
              distributeIntoLayers(items, 3),
          groupBy: customGroupBy,
          direction: GraphDirection.topToBottom,
        );

        expect(result.keys.toSet(), equals(items.toSet()));

        final groupAPlacement = result["a"]!;
        final groupBPlacement = result["d"]!;

        final aBounds = GraphBounds(
          groupAPlacement.x,
          groupAPlacement.y,
          groupAPlacement.x + groupAPlacement.width,
          groupAPlacement.y + groupAPlacement.height,
        );
        final bBounds = GraphBounds(
          groupBPlacement.x,
          groupBPlacement.y,
          groupBPlacement.x + groupBPlacement.width,
          groupBPlacement.y + groupBPlacement.height,
        );

        expect(
          !aBounds.overlapsWith(bBounds),
          isTrue,
          reason: "Items from different groups should not overlap",
        );
      });
    });
  });
}
