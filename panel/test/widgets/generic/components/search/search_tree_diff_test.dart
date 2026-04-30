import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_diff.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";

void main() {
  group("diffSearchTreeRows", () {
    test("no changes returns no operations", () {
      final diff = diffSearchTreeRows(previous: [_row("a")], next: [_row("a")]);

      expect(diff.removals, isEmpty);
      expect(diff.insertions, isEmpty);
    });

    test("removed key returns one removal", () {
      final diff = diffSearchTreeRows(previous: [_row("a")], next: []);

      expect(diff.removals, hasLength(1));
      expect(diff.removals.single.index, 0);
      expect(diff.removals.single.row.key, "a");
      expect(diff.insertions, isEmpty);
    });

    test("added key returns one insertion", () {
      final diff = diffSearchTreeRows(previous: [], next: [_row("a")]);

      expect(diff.removals, isEmpty);
      expect(diff.insertions, hasLength(1));
      expect(diff.insertions.single.index, 0);
      expect(diff.insertions.single.row.key, "a");
    });

    test("removal indices are descending", () {
      final diff = diffSearchTreeRows(
        previous: [_row("a"), _row("b"), _row("c")],
        next: [],
      );

      expect(diff.removals.map((removal) => removal.index), [2, 1, 0]);
    });

    test("insertion indices match the next list", () {
      final diff = diffSearchTreeRows(
        previous: [_row("a")],
        next: [_row("a"), _row("b"), _row("c")],
      );

      expect(diff.insertions.map((insertion) => insertion.index), [1, 2]);
    });

    test("insertion before existing rows keeps shifted stable rows", () {
      final diff = diffSearchTreeRows(
        previous: [_row("1"), _row("3"), _row("4")],
        next: [_row("1"), _row("2"), _row("3"), _row("4")],
      );

      expect(diff.removals, isEmpty);
      expect(diff.insertions.map((insertion) => insertion.row.key), ["2"]);
    });

    test("removal before existing rows keeps shifted stable rows", () {
      final diff = diffSearchTreeRows(
        previous: [_row("1"), _row("2"), _row("3"), _row("4")],
        next: [_row("1"), _row("3"), _row("4")],
      );

      expect(diff.removals.map((removal) => removal.row.key), ["2"]);
      expect(diff.insertions, isEmpty);
    });

    test("middle insertions and removals keep stable rows", () {
      final diff = diffSearchTreeRows(
        previous: [_row("1"), _row("3"), _row("4"), _row("6"), _row("7")],
        next: [_row("1"), _row("2"), _row("4"), _row("5"), _row("7")],
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

    test("reordered key returns one removal and insertion", () {
      final diff = diffSearchTreeRows(
        previous: [_row("a"), _row("b")],
        next: [_row("b"), _row("a")],
      );

      expect(diff.removals, hasLength(1));
      expect(diff.insertions, hasLength(1));
    });
  });
}

SearchTreeRow _row(String key) {
  return SearchTreeSectionRow(
    key: key,
    depth: 0,
    id: key,
    title: key,
    subtitle: null,
    expanded: true,
    resultCount: 0,
    topLevel: false,
  );
}
