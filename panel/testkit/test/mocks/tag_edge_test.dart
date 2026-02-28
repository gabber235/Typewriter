import "dart:math" as math;

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_testkit/src/mocks/graph_layout.dart";
import "package:typewriter_testkit/src/mocks/tag.mock.dart";

// ============ HELPER FUNCTIONS ============

/// Creates a test tag with specified id and parents
Tag createTestTagWithParents(String id, List<String> parentIds) {
  return Tag(
    id: id,
    name: "tag_$id",
    color: Color()..value = 0xFF0000,
    parents: parentIds.map((pid) => Tag(id: pid)).toList(),
  );
}

/// Detects if there's a cycle in parent references
bool hasCycle(List<Tag> tags) {
  final tagMap = {for (final t in tags) t.id: t};

  bool detectCycle(String id, Set<String> visited, Set<String> path) {
    if (path.contains(id)) return true;
    if (visited.contains(id)) return false;

    visited.add(id);
    path.add(id);

    final tag = tagMap[id];
    if (tag != null) {
      for (final parent in tag.parents) {
        if (detectCycle(parent.id, visited, path)) return true;
      }
    }

    path.remove(id);
    return false;
  }

  final visited = <String>{};
  for (final tag in tags) {
    if (detectCycle(tag.id, visited, {})) return true;
  }
  return false;
}

/// Clusters tags by detecting spatial gaps in placements
/// Tags in the same cluster have overlapping or nearby bounds
Map<int, Set<String>> clusterTagsByPlacement(List<Tag> tags, {int maxGap = 5}) {
  if (tags.isEmpty) return {};

  // Sort by Y then X to group spatially
  final sorted = tags.toList()
    ..sort((a, b) {
      final yCompare = a.placement.y.compareTo(b.placement.y);
      return yCompare != 0 ? yCompare : a.placement.x.compareTo(b.placement.x);
    });

  final clusters = <int, Set<String>>{};
  final tagToCluster = <String, int>{};
  var clusterIndex = 0;

  for (final tag in sorted) {
    int? foundCluster;

    // Check if this tag is close to any existing cluster
    for (final entry in clusters.entries) {
      for (final otherId in entry.value) {
        final other = tags.firstWhere((t) => t.id == otherId);
        if (arePlacementsInSameCluster(
          tag.placement,
          other.placement,
          maxGap: maxGap,
        )) {
          foundCluster = entry.key;
          break;
        }
      }
      if (foundCluster != null) break;
    }

    if (foundCluster != null) {
      clusters[foundCluster]!.add(tag.id);
      tagToCluster[tag.id] = foundCluster;
    } else {
      clusters[clusterIndex] = {tag.id};
      tagToCluster[tag.id] = clusterIndex;
      clusterIndex++;
    }
  }

  return clusters;
}

/// Check if two placements are spatially close (in same cluster)
bool arePlacementsInSameCluster(Placement a, Placement b, {int maxGap = 5}) {
  // Check if bounding boxes overlap or are within maxGap
  final aRight = a.x + a.width;
  final aBottom = a.y + a.height;
  final bRight = b.x + b.width;
  final bBottom = b.y + b.height;

  final xOverlap = a.x <= bRight + maxGap && aRight >= b.x - maxGap;
  final yOverlap = a.y <= bBottom + maxGap && aBottom >= b.y - maxGap;

  return xOverlap && yOverlap;
}

/// Calculate Manhattan distance between two placements
int manhattanDistance(Placement a, Placement b) {
  final dx = (a.x - b.x).abs();
  final dy = (a.y - b.y).abs();
  return dx + dy;
}

void main() {
  group("Tag Edge Diagnostics", () {
    // ============ EDGE VALIDITY ============

    group("Edge Validity", () {
      test("all parent references exist in tag list", () {
        final tags = generateTagBatch(20);
        final tagIds = tags.map((t) => t.id).toSet();

        for (final tag in tags) {
          for (final parent in tag.parents) {
            expect(
              tagIds.contains(parent.id),
              isTrue,
              reason:
                  "Parent ${parent.id} of tag ${tag.id} should exist in tag list",
            );
          }
        }
      });

      test("no self-referential parents", () {
        final tags = generateTagBatch(20);

        for (final tag in tags) {
          for (final parent in tag.parents) {
            expect(
              parent.id,
              isNot(equals(tag.id)),
              reason: "Tag ${tag.id} should not parent itself",
            );
          }
        }
      });

      test("no circular parent references", () {
        final tags = generateTagBatch(20);
        expect(
          hasCycle(tags),
          isFalse,
          reason: "Tags should not have circular parent references",
        );
      });
    });

    // ============ SPATIAL COHERENCE ============

    group("Spatial Coherence", () {
      test("connected tags share reasonable spatial proximity", () {
        for (var run = 0; run < 5; run++) {
          final tags = generateTagBatch(20);
          final layoutTags = applyTagLayout(tags);
          final tagMap = {for (final t in layoutTags) t.id: t};

          for (final tag in layoutTags) {
            for (final parentRef in tag.parents) {
              final parent = tagMap[parentRef.id];
              if (parent == null) continue;

              final distance = manhattanDistance(
                tag.placement,
                parent.placement,
              );

              expect(
                distance,
                lessThan(50),
                reason:
                    "Run $run: Connected tags ${parent.id} and ${tag.id} should be spatially close (distance=$distance)",
              );
            }
          }
        }
      });

      test("parent placement is above child in topToBottom", () {
        for (var run = 0; run < 5; run++) {
          final tags = generateTagBatch(15);
          final layoutTags = applyTagLayout(tags);
          final tagMap = {for (final t in layoutTags) t.id: t};

          for (final tag in layoutTags) {
            for (final parentRef in tag.parents) {
              final parent = tagMap[parentRef.id];
              if (parent == null) continue;

              expect(
                parent.placement.y,
                lessThanOrEqualTo(tag.placement.y),
                reason:
                    "Run $run: Parent ${parent.id} (y=${parent.placement.y}) should be at or above child ${tag.id} (y=${tag.placement.y})",
              );
            }
          }
        }
      });

      test("connected tags are within reasonable distance", () {
        for (var run = 0; run < 5; run++) {
          final tags = generateTagBatch(20);
          final layoutTags = applyTagLayout(tags);
          final tagMap = {for (final t in layoutTags) t.id: t};

          for (final tag in layoutTags) {
            for (final parentRef in tag.parents) {
              final parent = tagMap[parentRef.id];
              if (parent == null) continue;

              final distance = manhattanDistance(
                tag.placement,
                parent.placement,
              );

              // Within same group, distance should be bounded
              // A typical group with 3 width, 1 height, 2 spacing = ~20 units max
              expect(
                distance,
                lessThan(30),
                reason:
                    "Run $run: Connected tags ${parent.id} and ${tag.id} should be spatially close (distance=$distance)",
              );
            }
          }
        }
      });
    });

    // ============ GROUP SPLITTING ============

    group("Group Splitting", () {
      test("splitIntoGroups is position-based, not relationship-aware", () {
        // This test documents that splitIntoGroups is purely position-based.
        // For relationship-aware grouping, use groupTagsByConnectedComponents.
        final tagA = createTestTagWithParents("a", []);
        final tagB = createTestTagWithParents("b", ["a"]);
        final tagC = createTestTagWithParents("c", ["b"]);
        final tagD = createTestTagWithParents("d", []);
        final tagE = createTestTagWithParents("e", ["d"]);
        final tagF = createTestTagWithParents("f", ["e"]);
        final tagG = createTestTagWithParents("g", []);
        final tagH = createTestTagWithParents("h", ["g"]);

        final tags = [tagA, tagB, tagC, tagD, tagE, tagF, tagG, tagH];

        final groups = splitIntoGroups(tags, [4, 4]);

        expect(groups.length, equals(2));
        expect(
          groups[0].map((t) => t.id).toList(),
          equals(["a", "b", "c", "d"]),
        );
        expect(
          groups[1].map((t) => t.id).toList(),
          equals(["e", "f", "g", "h"]),
        );
      });

      test("generateGroupSizes returns reasonable sizes", () {
        for (var count = 1; count <= 50; count++) {
          final sizes = generateGroupSizes(count);

          expect(
            sizes.fold(0, (a, b) => a + b),
            equals(count),
            reason: "Group sizes should sum to $count",
          );
          expect(
            sizes.every((s) => s > 0),
            isTrue,
            reason: "All group sizes should be positive",
          );
        }
      });
    });

    // ============ DEPTH ORGANIZATION ============

    group("Depth Organization", () {
      test("organizeTagsByDepth puts parents before children", () {
        final tags = generateTagBatch(15);
        final layers = organizeTagsByDepth(tags);

        // Map tag to layer index
        final tagToLayer = <String, int>{};
        for (int i = 0; i < layers.length; i++) {
          for (final tag in layers[i]) {
            tagToLayer[tag.id] = i;
          }
        }

        for (final tag in tags) {
          for (final parentRef in tag.parents) {
            final parentLayer = tagToLayer[parentRef.id];
            final childLayer = tagToLayer[tag.id];
            if (parentLayer == null || childLayer == null) continue;

            expect(
              parentLayer,
              lessThan(childLayer),
              reason:
                  "Parent ${parentRef.id} (layer $parentLayer) should be before child ${tag.id} (layer $childLayer)",
            );
          }
        }
      });

      test("organizeTagsByDepth handles multiple parents correctly", () {
        final tagA = createTestTagWithParents("a", []);
        final tagB = createTestTagWithParents("b", []);
        final tagC = createTestTagWithParents("c", ["a", "b"]);
        final tags = [tagA, tagB, tagC];

        final layers = organizeTagsByDepth(tags);

        expect(layers.length, equals(2));
        expect(layers[0].map((t) => t.id).toSet(), equals({"a", "b"}));
        expect(layers[1].first.id, equals("c"));
      });
    });

    // ============ LAYOUT INTEGRATION ============

    group("Layout Integration", () {
      test("applyTagLayout assigns placements to all tags", () {
        final tags = generateTagBatch(20);
        final layoutTags = applyTagLayout(tags);

        expect(layoutTags.length, equals(20));
        for (final tag in layoutTags) {
          expect(
            tag.hasPlacement(),
            isTrue,
            reason: "Tag ${tag.id} should have a placement",
          );
        }
      });

      test("tags in same layer have similar main-axis position", () {
        final tags = generateTagBatch(15);
        final layers = organizeTagsByDepth(tags);
        final layoutTags = applyTagLayout(tags);
        final tagMap = {for (final t in layoutTags) t.id: t};

        for (final layer in layers) {
          if (layer.length < 2) continue;

          // In topToBottom, same layer = same Y
          final yValues = layer.map((t) => tagMap[t.id]!.placement.y).toSet();

          // Allow some variation due to group offsets
          final minY = yValues.reduce(math.min);
          final maxY = yValues.reduce(math.max);
          final spread = maxY - minY;

          // If all in same group, spread should be minimal
          // This test may fail if items from same layer end up in different groups
          expect(
            spread,
            lessThanOrEqualTo(20),
            reason:
                "Tags in same layer should have similar Y positions (spread=$spread)",
          );
        }
      });
    });
  });
}
