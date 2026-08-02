import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart" show RecordIdExtension;
import "package:typewriter_testkit/features/organizations.dart";

void main() {
  group("Tag Layout", () {
    group("generateTagBatch", () {
      test("returns empty list for count <= 0", () {
        expect(generateTagBatch(0), isEmpty);
        expect(generateTagBatch(-1), isEmpty);
      });

      test("generates correct number of tags", () {
        final tags = generateTagBatch(5);
        expect(tags.length, equals(5));
      });

      test("all tags have unique IDs", () {
        final tags = generateTagBatch(10);
        final ids = tags.map((t) => t.tagId).toSet();
        expect(ids.length, equals(10));
      });

      test("all tags have valid placements", () {
        final tags = generateTagBatch(10);
        for (final tag in tags) {
          expect(tag.placement.width, greaterThan(0));
          expect(tag.placement.height, greaterThan(0));
          expect(tag.placement.x, greaterThanOrEqualTo(0));
          expect(tag.placement.y, greaterThanOrEqualTo(0));
        }
      });

      test("parent references are valid (point to existing tags)", () {
        final tags = generateTagBatch(20);
        final allIds = tags.map((t) => t.tagId).toSet();

        for (final tag in tags) {
          for (final parentId in tag.parentIds) {
            expect(
              allIds.contains(parentId),
              isTrue,
              reason: "Parent $parentId should exist in generated list",
            );
          }
        }
      });

      test("parents have lower or equal Y than children (top-to-bottom)", () {
        final tags = generateTagBatch(20);
        final tagById = {for (final t in tags) t.tagId: t};

        for (final tag in tags) {
          for (final parentId in tag.parentIds) {
            final parent = tagById[parentId];
            if (parent != null) {
              expect(
                parent.placement.y,
                lessThanOrEqualTo(tag.placement.y),
                reason:
                    "Parent ${parent.tagId} should be above or equal to child ${tag.tagId}",
              );
            }
          }
        }
      });

      test("no placements overlap", () {
        final tags = generateTagBatch(30);

        for (int i = 0; i < tags.length; i++) {
          for (int j = i + 1; j < tags.length; j++) {
            final a = tags[i].placement;
            final b = tags[j].placement;

            final overlapsX = a.x < b.x + b.width && a.x + a.width > b.x;
            final overlapsY = a.y < b.y + b.height && a.y + a.height > b.y;
            final overlaps = overlapsX && overlapsY;

            expect(
              overlaps,
              isFalse,
              reason:
                  "Tags ${tags[i].tagId} and ${tags[j].tagId} overlap at (${a.x},${a.y}) and (${b.x},${b.y})",
            );
          }
        }
      });

      test("handles single tag", () {
        final tags = generateTagBatch(1);
        expect(tags.length, equals(1));
        expect(tags.first.parentIds, isEmpty);
        expect(tags.first.placement.x, equals(0));
        expect(tags.first.placement.y, equals(0));
      });

      test("handles large batch without errors", () {
        final tags = generateTagBatch(100);
        expect(tags.length, equals(100));

        final allIds = tags.map((t) => t.tagId).toSet();
        for (final tag in tags) {
          for (final parentId in tag.parentIds) {
            expect(allIds.contains(parentId), isTrue);
          }
        }
      });
    });

    group("generateRandomTag", () {
      test("generates tag with valid id and name", () {
        final tag = generateRandomTag();
        expect(tag.tagId.id, isNotEmpty);
        expect(tag.name, isNotEmpty);
      });

      test("generates tag with valid placement", () {
        final tag = generateRandomTag();
        expect(tag.placement.width, greaterThan(0));
        expect(tag.placement.height, greaterThan(0));
      });

      test("generates tag with no parents", () {
        final tag = generateRandomTag();
        expect(tag.parentIds, isEmpty);
      });
    });
  });
}
