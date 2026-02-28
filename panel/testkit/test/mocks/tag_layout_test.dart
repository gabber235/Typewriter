import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_panel/logic/pages/graph_direction.dart";
import "package:typewriter_testkit/src/mocks/graph_layout.dart";
import "package:typewriter_testkit/src/mocks/tag.mock.dart";

Tag createTestTag(String id, {List<String> parentIds = const []}) {
  return Tag(
    id: id,
    name: "tag_$id",
    color: Color()..value = 0xFF0000,
    parents: parentIds.map((pid) => Tag(id: pid)).toList(),
  );
}

void main() {
  group("Tag Layout", () {
    // ============ organizeTagsByDepth ============

    group("organizeTagsByDepth", () {
      test("returns empty for empty input", () {
        final result = organizeTagsByDepth([]);
        expect(result, isEmpty);
      });

      test("puts root tags (no parents) in layer 0", () {
        final tags = [
          createTestTag("a"),
          createTestTag("b"),
          createTestTag("c"),
        ];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(1));
        expect(result.first.length, equals(3));
      });

      test("puts children in layer after parents", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tags = [tagA, tagB];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(2));
        expect(result[0].map((t) => t.id).toList(), equals(["a"]));
        expect(result[1].map((t) => t.id).toList(), equals(["b"]));
      });

      test("handles multiple roots", () {
        final tags = [
          createTestTag("root1"),
          createTestTag("root2"),
          createTestTag("root3"),
        ];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(1));
        expect(result.first.length, equals(3));
      });

      test("handles deep hierarchy", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tagC = createTestTag("c", parentIds: ["b"]);
        final tagD = createTestTag("d", parentIds: ["c"]);
        final tags = [tagA, tagB, tagC, tagD];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(4));
        expect(result[0].first.id, equals("a"));
        expect(result[1].first.id, equals("b"));
        expect(result[2].first.id, equals("c"));
        expect(result[3].first.id, equals("d"));
      });

      test("handles tags with multiple parents", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b");
        final tagC = createTestTag("c", parentIds: ["a", "b"]);
        final tags = [tagA, tagB, tagC];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(2));
        expect(result[0].map((t) => t.id).toSet(), equals({"a", "b"}));
        expect(result[1].first.id, equals("c"));
      });

      test("handles missing parent references", () {
        final tagWithMissingParent = createTestTag("x", parentIds: ["missing"]);
        final tags = [tagWithMissingParent];

        final result = organizeTagsByDepth(tags);

        expect(result.length, equals(1));
        expect(result.first.first.id, equals("x"));
      });

      test("filters empty layers", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tags = [tagA, tagB];

        final result = organizeTagsByDepth(tags);

        expect(result.every((layer) => layer.isNotEmpty), isTrue);
      });
    });

    // ============ generateTagBatch ============

    group("generateTagBatch", () {
      test("returns empty for count <= 0", () {
        expect(generateTagBatch(0), isEmpty);
        expect(generateTagBatch(-1), isEmpty);
      });

      test("generates correct number of tags", () {
        final tags = generateTagBatch(5);
        expect(tags.length, equals(5));
      });

      test("first tag has no parents", () {
        final tags = generateTagBatch(3);
        expect(tags.first.parents, isEmpty);
      });

      test("all tags have unique IDs", () {
        final tags = generateTagBatch(10);
        final ids = tags.map((t) => t.id).toSet();
        expect(ids.length, equals(10));
      });

      test("parent references point to earlier tags", () {
        final tags = generateTagBatch(10);

        for (int i = 0; i < tags.length; i++) {
          for (final parent in tags[i].parents) {
            final parentIndex = tags.indexWhere((t) => t.id == parent.id);
            expect(
              parentIndex,
              lessThan(i),
              reason: "Parent of tag $i should be at an earlier index",
            );
          }
        }
      });

      test("parent references are valid", () {
        final tags = generateTagBatch(10);
        final allIds = tags.map((t) => t.id).toSet();

        for (final tag in tags) {
          for (final parent in tag.parents) {
            expect(
              allIds.contains(parent.id),
              isTrue,
              reason: "Parent ${parent.id} should exist in generated list",
            );
          }
        }
      });
    });

    // ============ applyTagLayout ============

    group("applyTagLayout", () {
      test("returns empty for empty input", () {
        final result = applyTagLayout([]);
        expect(result, isEmpty);
      });

      test("assigns placement to all tags", () {
        final tags = [
          createTestTag("a"),
          createTestTag("b", parentIds: ["a"]),
          createTestTag("c", parentIds: ["b"]),
        ];

        final result = applyTagLayout(tags);

        expect(result.length, equals(3));
        for (final tag in result) {
          expect(tag.hasPlacement(), isTrue);
        }
      });

      test("preserves tag properties", () {
        final tags = [createTestTag("test_id")];

        final result = applyTagLayout(tags);

        expect(result.first.id, equals("test_id"));
        expect(result.first.name, equals("tag_test_id"));
        expect(result.first.hasColor(), isTrue);
      });

      test("uses topToBottom direction", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tags = [tagA, tagB];

        final result = applyTagLayout(tags);

        final placementA = result.firstWhere((t) => t.id == "a").placement;
        final placementB = result.firstWhere((t) => t.id == "b").placement;

        expect(placementB.y, greaterThan(placementA.y));
      });
    });

    // ============ groupTagsByConnectedComponents ============

    group("groupTagsByConnectedComponents", () {
      test("returns empty for empty input", () {
        final result = groupTagsByConnectedComponents([]);
        expect(result, isEmpty);
      });

      test("single connected tree returns one component", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tagC = createTestTag("c", parentIds: ["b"]);
        final tags = [tagA, tagB, tagC];

        final result = groupTagsByConnectedComponents(tags);

        expect(result.length, equals(1));
        expect(result.first.length, equals(3));
      });

      test("multiple disconnected trees return multiple components", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b", parentIds: ["a"]);
        final tagC = createTestTag("c");
        final tagD = createTestTag("d", parentIds: ["c"]);
        final tagE = createTestTag("e");
        final tags = [tagA, tagB, tagC, tagD, tagE];

        final result = groupTagsByConnectedComponents(tags);

        expect(result.length, equals(3));
        final componentIds = result
            .map((c) => c.map((t) => t.id).toSet())
            .toList();

        expect(componentIds.any((c) => c.containsAll(["a", "b"])), isTrue);
        expect(componentIds.any((c) => c.containsAll(["c", "d"])), isTrue);
        expect(componentIds.any((c) => c.contains("e")), isTrue);
      });

      test("handles tags with multiple parents", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b");
        final tagC = createTestTag("c", parentIds: ["a", "b"]);
        final tags = [tagA, tagB, tagC];

        final result = groupTagsByConnectedComponents(tags);

        expect(result.length, equals(1));
        expect(result.first.length, equals(3));
      });

      test("handles orphaned tags", () {
        final tagA = createTestTag("a");
        final tagB = createTestTag("b");
        final tagC = createTestTag("c");
        final tags = [tagA, tagB, tagC];

        final result = groupTagsByConnectedComponents(tags);

        expect(result.length, equals(3));
      });

      test("ignores missing parent references", () {
        final tagA = createTestTag("a", parentIds: ["missing"]);
        final tagB = createTestTag("b");
        final tags = [tagA, tagB];

        final result = groupTagsByConnectedComponents(tags);

        expect(result.length, equals(2));
      });
    });

    // ============ Integration with graph_layout ============

    group("integration", () {
      test("organizeTagsByDepth works with layoutLayers", () {
        final tags = generateTagBatch(8);
        final layers = organizeTagsByDepth(tags);

        final placements = layoutLayers<Tag>(
          layers: layers,
          getId: (t) => t.id,
          direction: GraphDirection.topToBottom,
        );

        expect(placements.length, equals(8));
        for (final tag in tags) {
          expect(placements.containsKey(tag.id), isTrue);
        }
      });

      test("generateDynamicLayout creates valid tag layout", () {
        final tags = generateTagBatch(15);

        final placements = generateDynamicLayout<Tag>(
          items: tags,
          getId: (t) => t.id,
          organizeIntoLayers: organizeTagsByDepth,
          direction: GraphDirection.topToBottom,
        );

        expect(placements.length, equals(15));

        final bounds = placements.values
            .map((p) => GraphBounds(p.x, p.y, p.x + p.width, p.y + p.height))
            .toList();

        for (int i = 0; i < bounds.length; i++) {
          for (int j = i + 1; j < bounds.length; j++) {
            expect(
              bounds[i].overlapsWith(bounds[j]),
              isFalse,
              reason: "Tags should not overlap",
            );
          }
        }
      });
    });
  });
}
