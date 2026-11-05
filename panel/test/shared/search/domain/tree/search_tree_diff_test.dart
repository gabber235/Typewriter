import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("diffSearchTreeRows", () {
    test("no changes returns no operations", () {
      final diff = replayedSearchTreeDiff(
        previous: [searchSectionRow("a")],
        next: [searchSectionRow("a")],
      );

      expect(diff.removals, isEmpty);
      expect(diff.insertions, isEmpty);
    });

    test("removed key returns one removal", () {
      final diff = replayedSearchTreeDiff(
        previous: [searchSectionRow("a")],
        next: [],
      );

      expect(diff.removals, hasLength(1));
      expect(diff.removals.single.index, 0);
      expect(diff.removals.single.row.key, "a");
      expect(diff.insertions, isEmpty);
    });

    test("added key returns one insertion", () {
      final diff = replayedSearchTreeDiff(
        previous: [],
        next: [searchSectionRow("a")],
      );

      expect(diff.removals, isEmpty);
      expect(diff.insertions, hasLength(1));
      expect(diff.insertions.single.index, 0);
      expect(diff.insertions.single.row.key, "a");
    });

    test("removal indices are descending", () {
      final diff = replayedSearchTreeDiff(
        previous: [
          searchSectionRow("a"),
          searchSectionRow("b"),
          searchSectionRow("c"),
        ],
        next: [],
      );

      expect(diff.removals.map((removal) => removal.index), [2, 1, 0]);
    });

    test("insertion indices match the next list", () {
      final diff = replayedSearchTreeDiff(
        previous: [searchSectionRow("a")],
        next: [
          searchSectionRow("a"),
          searchSectionRow("b"),
          searchSectionRow("c"),
        ],
      );

      expect(diff.insertions.map((insertion) => insertion.index), [1, 2]);
    });

    test("insertion before existing rows keeps shifted stable rows", () {
      final diff = replayedSearchTreeDiff(
        previous: [
          searchSectionRow("1"),
          searchSectionRow("3"),
          searchSectionRow("4"),
        ],
        next: [
          searchSectionRow("1"),
          searchSectionRow("2"),
          searchSectionRow("3"),
          searchSectionRow("4"),
        ],
      );

      expect(diff.removals, isEmpty);
      expect(diff.insertions.map((insertion) => insertion.row.key), ["2"]);
    });

    test("removal before existing rows keeps shifted stable rows", () {
      final diff = replayedSearchTreeDiff(
        previous: [
          searchSectionRow("1"),
          searchSectionRow("2"),
          searchSectionRow("3"),
          searchSectionRow("4"),
        ],
        next: [
          searchSectionRow("1"),
          searchSectionRow("3"),
          searchSectionRow("4"),
        ],
      );

      expect(diff.removals.map((removal) => removal.row.key), ["2"]);
      expect(diff.insertions, isEmpty);
    });

    test("middle insertions and removals keep stable rows", () {
      final diff = replayedSearchTreeDiff(
        previous: [
          searchSectionRow("1"),
          searchSectionRow("3"),
          searchSectionRow("4"),
          searchSectionRow("6"),
          searchSectionRow("7"),
        ],
        next: [
          searchSectionRow("1"),
          searchSectionRow("2"),
          searchSectionRow("4"),
          searchSectionRow("5"),
          searchSectionRow("7"),
        ],
      );

      expect(diff.removals.map((removal) => removal.row.key), ["6", "3"]);
      expect(diff.insertions.map((insertion) => insertion.row.key), ["2", "5"]);
      expect(
        diff.removals.map((removal) => removal.row.key),
        isNot(containsAll(["1", "4", "7"])),
      );
      expect(
        diff.insertions.map((insertion) => insertion.row.key),
        isNot(containsAll(["1", "4", "7"])),
      );
    });

    test("a reordered key moves by one removal and one insertion", () {
      final diff = replayedSearchTreeDiff(
        previous: [searchSectionRow("a"), searchSectionRow("b")],
        next: [searchSectionRow("b"), searchSectionRow("a")],
      );

      expect(diff.removals.map((removal) => removal.row.key), ["a"]);
      expect(diff.insertions.map((insertion) => insertion.row.key), ["a"]);
      expect(diff.insertions.single.index, 1);
    });
  });
}
