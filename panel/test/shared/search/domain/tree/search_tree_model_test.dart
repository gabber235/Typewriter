import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("buildSearchTreeViewModel", () {
    test("builds one top level group for one top level section", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [
          sectionNode("books", [resultNode("book-one")], title: "Books"),
        ],
        isCollapsed: (_) => false,
      );

      expect(viewModel.groups, hasLength(1));
      expect(viewModel.groups.single.section!.id, "books");
      expect(viewModel.groups.single.section!.topLevel, isTrue);
    });

    test("computes descendant counts in the same build", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [
          sectionNode("root", [
            resultNode("alpha"),
            SearchNode.section(
              id: "nested",
              title: "Nested",
              children: [resultNode("beta")],
            ),
          ], title: "Root"),
        ],
        isCollapsed: (_) => false,
      );

      expect(viewModel.groups.single.section!.resultCount, 2);
      final nested = viewModel.groups.single.rows
          .whereType<SearchTreeSectionRow>()
          .single;
      expect(nested.resultCount, 1);
    });

    test("sections are expanded by default", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [sectionNode("root", const [], title: "Root")],
        isCollapsed: (_) => false,
      );

      expect(viewModel.groups.single.section!.expanded, isTrue);
    });

    test("collapsed sections keep section rows and hide descendants", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [
          sectionNode("root", [resultNode("alpha")], title: "Root"),
        ],
        isCollapsed: {"root"}.contains,
      );

      expect(viewModel.groups.single.section!.id, "root");
      expect(viewModel.groups.single.section!.expanded, isFalse);
      expect(viewModel.groups.single.rows, isEmpty);
      expect(viewModel.rowCount, 1);
    });

    test("collapsed nested section remains in parent group rows", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: nestedSectionTree([resultNode("alpha")]),
        isCollapsed: {"nested"}.contains,
      );

      final rows = viewModel.groups.single.rows;
      final nested = rows.whereType<SearchTreeSectionRow>().single;

      expect(nested.id, "nested");
      expect(nested.expanded, isFalse);
      expect(rows.whereType<SearchTreeResultRow>(), isEmpty);
    });

    test("collapsed nested section descendants are hidden", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: nestedSectionTree([resultNode("alpha"), resultNode("beta")]),
        isCollapsed: {"nested"}.contains,
      );

      expect(
        viewModel.groups.single.rows.whereType<SearchTreeResultRow>(),
        isEmpty,
      );
      expect(viewModel.groups.single.section!.resultCount, 2);
    });

    test("nested section rows appear in the parent group body", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: nestedSectionTree([resultNode("alpha")]),
        isCollapsed: (_) => false,
      );

      final nested = viewModel.groups.single.rows
          .whereType<SearchTreeSectionRow>()
          .single;
      expect(nested.id, "nested");
      expect(nested.depth, 1);
      expect(nested.topLevel, isFalse);
    });

    test("visible result rows one through nine receive shortcuts", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [for (var i = 1; i <= 10; i++) resultNode("item$i")],
        isCollapsed: (_) => false,
      );
      final rows = viewModel.groups.single.rows
          .whereType<SearchTreeResultRow>()
          .toList();

      expect(rows.take(9).map((row) => row.shortcutNumber), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      ]);
      expect(rows[9].shortcutNumber, isNull);
    });

    test("hidden result rows do not consume shortcut numbers", () {
      final viewModel = buildSearchTreeViewModel(
        nodes: [
          sectionNode("hidden", [resultNode("hidden-result")], title: "Hidden"),
          resultNode("visible-result"),
        ],
        isCollapsed: {"hidden"}.contains,
      );
      final looseGroup = viewModel.groups.last;
      final result = looseGroup.rows.whereType<SearchTreeResultRow>().single;

      expect(result.shortcutNumber, 1);
    });
  });
}
