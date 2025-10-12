import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:typewriter_panel/logic/pages/entries.dart';
import 'package:typewriter_panel/logic/selectable/data_blueprint.dart';
import 'package:typewriter_panel/logic/selectable/dynamic_data.dart';
import 'package:typewriter_panel/utils/color.dart';
import 'package:typewriter_panel/logic/pages/graph_direction.dart';
import 'package:typewriter_testkit/src/mocks/graph_layout.dart';

EntryDefinition createTestEntry() {
  return EntryDefinition(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" "),
    blueprint: EntryBlueprint(
      id: faker.guid.guid(),
      name: faker.lorem.word(),
      description: faker.lorem.sentence(),
      extension: "test",
      dataBlueprint: ObjectBlueprint(fields: {}),
      color: safeColors.first,
      icon: "fa-solid:star",
      tags: [],
    ),
    placement: const EntryPlacement(x: 0, y: 0, width: 0, height: 0),
    data: DynamicData({}),
    inwardEdges: [],
    outwardEdges: [],
  );
}

void main() {
  group('Graph Layout', () {
    test('generateGroupSizes creates valid group splits', () {
      final sizes1 = generateGroupSizes(10);
      expect(sizes1.fold(0, (a, b) => a + b), equals(10));
      expect(sizes1.length, greaterThanOrEqualTo(1));
      expect(sizes1.length, lessThanOrEqualTo(5));
      expect(sizes1.every((size) => size > 0), isTrue);

      final sizes2 = generateGroupSizes(3);
      expect(sizes2, equals([3]));
    });

    test('splitIntoGroups correctly divides entries', () {
      final entries = List.generate(6, (_) => createTestEntry());
      final groups = splitIntoGroups(entries, [2, 3, 1]);

      expect(groups.length, equals(3));
      expect(groups[0].length, equals(2));
      expect(groups[1].length, equals(3));
      expect(groups[2].length, equals(1));
    });

    test('distributeIntoLayers creates non-empty layers', () {
      final entries = List.generate(6, (_) => createTestEntry());
      final layers = distributeIntoLayers(entries, 3);

      expect(layers.every((layer) => layer.isNotEmpty), isTrue);
      final totalEntries = layers.fold(0, (sum, layer) => sum + layer.length);
      expect(totalEntries, equals(6));
    });

    test('GraphBounds calculates dimensions correctly', () {
      const bounds = GraphBounds(2, 3, 8, 7);
      expect(bounds.width, equals(7));
      expect(bounds.height, equals(5));
    });

    test('GraphBounds detects overlaps correctly', () {
      const bounds1 = GraphBounds(0, 0, 5, 5);
      const bounds2 = GraphBounds(3, 3, 8, 8);
      const bounds3 = GraphBounds(10, 10, 15, 15);

      expect(bounds1.overlaps(bounds2, 0, 0), isTrue);
      expect(bounds1.overlaps(bounds3, 0, 0), isFalse);
      expect(bounds2.overlaps(bounds3, 0, 0), isFalse);
    });

    test('GraphBounds overlapsWith method works correctly', () {
      const bounds1 = GraphBounds(0, 0, 5, 5);
      const bounds2 = GraphBounds(3, 3, 8, 8);
      const bounds3 = GraphBounds(10, 10, 15, 15);

      expect(bounds1.overlapsWith(bounds2), isTrue);
      expect(bounds1.overlapsWith(bounds3), isFalse);
      expect(bounds2.overlapsWith(bounds3), isFalse);
    });

    test('GraphBounds offset method works correctly', () {
      const bounds = GraphBounds(0, 0, 5, 5);
      final offsetBounds = bounds.offset(10, 20);

      expect(offsetBounds.minX, equals(10));
      expect(offsetBounds.minY, equals(20));
      expect(offsetBounds.maxX, equals(15));
      expect(offsetBounds.maxY, equals(25));
    });

    test('layoutSingleGraph creates correct layout structure', () {
      final entries = List.generate(4, (_) => createTestEntry());
      final layout = layoutSingleGraph(entries, GraphDirection.leftToRight);

      expect(layout.layers.isNotEmpty, isTrue);
      expect(layout.direction, equals(GraphDirection.leftToRight));
      expect(layout.bounds.width, greaterThan(0));
      expect(layout.bounds.height, greaterThan(0));

      final allEntries = layout.layers.expand((layer) => layer).toList();
      expect(allEntries.length, equals(4));

      for (final entry in allEntries) {
        expect(entry.placement.width, equals(3));
        expect(entry.placement.height, equals(1));
        expect(entry.placement.x, greaterThanOrEqualTo(0));
        expect(entry.placement.y, greaterThanOrEqualTo(0));
      }
    });

    test('crossPoints distributes points evenly', () {
      final points = crossPoints(3, 2, 20);
      expect(points.length, equals(3));

      for (final point in points) {
        expect(point, greaterThanOrEqualTo(0));
        expect(point, lessThanOrEqualTo(20));
      }
    });

    test('findNonOverlappingPosition finds valid positions', () {
      const existing1 = GraphBounds(0, 0, 5, 5);
      const existing2 = GraphBounds(10, 0, 15, 5);
      const newGraph = GraphBounds(0, 0, 3, 3);

      final position = findNonOverlappingPosition(
        newGraph,
        [existing1, existing2],
        GraphDirection.leftToRight,
      );

      expect(position.x, greaterThanOrEqualTo(0));
      expect(position.y, greaterThanOrEqualTo(0));

      final offsetBounds = newGraph.offset(position.x, position.y);
      expect(offsetBounds.overlapsWith(existing1), isFalse);
      expect(offsetBounds.overlapsWith(existing2), isFalse);
    });

    test('findNonOverlappingPosition handles empty existing graphs', () {
      const newGraph = GraphBounds(0, 0, 3, 3);
      final position = findNonOverlappingPosition(
        newGraph,
        [],
        GraphDirection.leftToRight,
      );

      expect(position.x, equals(0));
      expect(position.y, equals(0));
    });

    test('generateEdgesForLayers creates valid edges', () {
      final entries = List.generate(6, (_) => createTestEntry());
      final layers = [
        [entries[0], entries[1]],
        [entries[2], entries[3]],
        [entries[4], entries[5]],
      ];

      final edges = generateEdgesForLayers(layers);

      expect(edges.isNotEmpty, isTrue);

      for (final edge in edges) {
        expect(edge.id.contains('_'), isTrue);
        expect(edge.otherId.isNotEmpty, isTrue);
        expect(edge.path, equals('connections'));
      }
    });

    test('generateEdgesForLayers handles single layer', () {
      final entries = List.generate(3, (_) => createTestEntry());
      final layers = [entries];

      final edges = generateEdgesForLayers(layers);
      expect(edges, isEmpty);
    });

    test('applyEdgesToEntries correctly assigns edges', () {
      final entry1 = createTestEntry();
      final entry2 = createTestEntry();
      final entries = [entry1, entry2];

      final edge = EntryEdge(
        id: "${entry1.id}_${entry2.id}",
        otherId: entry2.id,
        path: "connections",
      );

      final updatedEntries = applyEdgesToEntries(entries, [edge]);

      expect(updatedEntries.length, equals(2));

      final updatedEntry1 = updatedEntries.firstWhere((e) => e.id == entry1.id);
      final updatedEntry2 = updatedEntries.firstWhere((e) => e.id == entry2.id);

      expect(updatedEntry1.outwardEdges.length, equals(1));
      expect(updatedEntry1.outwardEdges.first.otherId, equals(entry2.id));

      expect(updatedEntry2.inwardEdges.length, equals(1));
      expect(updatedEntry2.inwardEdges.first.otherId, equals(entry1.id));
    });

    test('generateDynamicGraphLayout creates complete layout', () {
      final entries = List.generate(8, (_) => createTestEntry());
      final layoutedEntries = generateDynamicGraphLayout(entries, null);

      expect(layoutedEntries.length, equals(8));

      for (final entry in layoutedEntries) {
        expect(entry.placement.x, greaterThanOrEqualTo(0));
        expect(entry.placement.y, greaterThanOrEqualTo(0));
        expect(entry.placement.width, equals(3));
        expect(entry.placement.height, equals(1));
      }

      final allEntryIds = layoutedEntries.map((e) => e.id).toSet();
      for (final entry in layoutedEntries) {
        for (final edge in entry.outwardEdges) {
          expect(allEntryIds.contains(edge.otherId), isTrue);
        }
        for (final edge in entry.inwardEdges) {
          expect(allEntryIds.contains(edge.otherId), isTrue);
        }
      }
    });

    test('generateDynamicGraphLayout respects specified direction', () {
      final entries = List.generate(6, (_) => createTestEntry());
      final layoutedEntries = generateDynamicGraphLayout(
        entries,
        GraphDirection.topToBottom,
      );

      expect(layoutedEntries.length, equals(6));

      for (final entry in layoutedEntries) {
        expect(entry.placement.x, greaterThanOrEqualTo(0));
        expect(entry.placement.y, greaterThanOrEqualTo(0));
        expect(entry.placement.width, equals(3));
        expect(entry.placement.height, equals(1));
      }

      final allEntryIds = layoutedEntries.map((e) => e.id).toSet();
      for (final entry in layoutedEntries) {
        for (final edge in entry.outwardEdges) {
          expect(allEntryIds.contains(edge.otherId), isTrue);
        }
        for (final edge in entry.inwardEdges) {
          expect(allEntryIds.contains(edge.otherId), isTrue);
        }
      }
    });

    test('layout creates reasonable spacing between graphs', () {
      final entries = List.generate(12, (_) => createTestEntry());
      final layoutedEntries = generateDynamicGraphLayout(entries, null);

      for (final entry in layoutedEntries) {
        expect(entry.placement.x, greaterThanOrEqualTo(0));
        expect(entry.placement.y, greaterThanOrEqualTo(0));
        expect(entry.placement.x, lessThan(1000));
        expect(entry.placement.y, lessThan(1000));
      }

      final xPositions = layoutedEntries.map((e) => e.placement.x).toSet();
      final yPositions = layoutedEntries.map((e) => e.placement.y).toSet();

      expect(xPositions.length, greaterThan(1));
      expect(yPositions.length, greaterThan(1));
    });

    test('Point class works correctly', () {
      const point = Point(5, 10);
      expect(point.x, equals(5));
      expect(point.y, equals(10));
    });

    test('LocalGraphLayout contains expected properties', () {
      final entries = List.generate(3, (_) => createTestEntry());
      final layout = layoutSingleGraph(entries, GraphDirection.rightToLeft);

      expect(layout.layers, isA<List<List<EntryDefinition>>>());
      expect(layout.direction, equals(GraphDirection.rightToLeft));
      expect(layout.bounds, isA<GraphBounds>());
      expect(layout.layers.isNotEmpty, isTrue);
    });
  });
}
