import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";

import "../../../../logic/search/core/search_core_test_harness.dart";

void main() {
  group("buildSearchTreeViewModel", () {
    test("builds one top level group for one top level section", () {
      final viewModel = _build([
        SearchNode.section(
          id: "books",
          title: "Books",
          children: [resultNode("book-one")],
        ),
      ]);

      expect(viewModel.groups, hasLength(1));
      expect(viewModel.groups.single.section!.id, "books");
      expect(viewModel.groups.single.section!.topLevel, isTrue);
    });

    test("computes descendant counts in the same build", () {
      final viewModel = _build([
        SearchNode.section(
          id: "root",
          title: "Root",
          children: [
            resultNode("alpha"),
            SearchNode.section(
              id: "nested",
              title: "Nested",
              children: [resultNode("beta")],
            ),
          ],
        ),
      ]);

      expect(viewModel.groups.single.section!.resultCount, 2);
      final nested = viewModel.groups.single.rows
          .whereType<SearchTreeSectionRow>()
          .single;
      expect(nested.resultCount, 1);
    });

    test("sections are expanded by default", () {
      final viewModel = _build([SearchNode.section(id: "root", title: "Root")]);

      expect(viewModel.groups.single.section!.expanded, isTrue);
    });

    test("collapsed sections keep section rows and hide descendants", () {
      final viewModel = _build(
        [
          SearchNode.section(
            id: "root",
            title: "Root",
            children: [resultNode("alpha")],
          ),
        ],
        collapsedIds: {"root"},
      );

      expect(viewModel.groups.single.section!.expanded, isFalse);
      expect(viewModel.groups.single.rows, isEmpty);
      expect(viewModel.rowCount, 1);
    });

    test("collapsed top level section remains as group header", () {
      final viewModel = _build(
        [
          SearchNode.section(
            id: "root",
            title: "Root",
            children: [resultNode("alpha")],
          ),
        ],
        collapsedIds: {"root"},
      );

      expect(viewModel.groups.single.section, isA<SearchTreeSectionRow>());
      expect(viewModel.groups.single.section!.id, "root");
      expect(viewModel.groups.single.section!.expanded, isFalse);
    });

    test("collapsed nested section remains in parent group rows", () {
      final viewModel = _build(
        [
          SearchNode.section(
            id: "root",
            title: "Root",
            children: [
              SearchNode.section(
                id: "nested",
                title: "Nested",
                children: [resultNode("alpha")],
              ),
            ],
          ),
        ],
        collapsedIds: {"nested"},
      );

      final rows = viewModel.groups.single.rows;
      final nested = rows.whereType<SearchTreeSectionRow>().single;

      expect(nested.id, "nested");
      expect(nested.expanded, isFalse);
      expect(rows.whereType<SearchTreeResultRow>(), isEmpty);
    });

    test("collapsed nested section descendants are hidden", () {
      final viewModel = _build(
        [
          SearchNode.section(
            id: "root",
            title: "Root",
            children: [
              SearchNode.section(
                id: "nested",
                title: "Nested",
                children: [resultNode("alpha"), resultNode("beta")],
              ),
            ],
          ),
        ],
        collapsedIds: {"nested"},
      );

      expect(
        viewModel.groups.single.rows.whereType<SearchTreeResultRow>(),
        isEmpty,
      );
      expect(viewModel.groups.single.section!.resultCount, 2);
    });

    test("hidden descendants still contribute to section count", () {
      final viewModel = _build(
        [
          SearchNode.section(
            id: "root",
            title: "Root",
            children: [resultNode("alpha"), resultNode("beta")],
          ),
        ],
        collapsedIds: {"root"},
      );

      expect(viewModel.groups.single.section!.resultCount, 2);
    });

    test("nested section rows appear in the parent group body", () {
      final viewModel = _build([
        SearchNode.section(
          id: "root",
          title: "Root",
          children: [
            SearchNode.section(
              id: "nested",
              title: "Nested",
              children: [resultNode("alpha")],
            ),
          ],
        ),
      ]);

      final nested = viewModel.groups.single.rows
          .whereType<SearchTreeSectionRow>()
          .single;
      expect(nested.id, "nested");
      expect(nested.depth, 1);
      expect(nested.topLevel, isFalse);
    });

    test("visible result rows one through nine receive shortcuts", () {
      final viewModel = _build([
        for (var i = 1; i <= 10; i++) resultNode("item$i"),
      ]);
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
      final viewModel = _build(
        [
          SearchNode.section(
            id: "hidden",
            title: "Hidden",
            children: [resultNode("hidden-result")],
          ),
          resultNode("visible-result"),
        ],
        collapsedIds: {"hidden"},
      );
      final looseGroup = viewModel.groups.last;
      final result = looseGroup.rows.whereType<SearchTreeResultRow>().single;

      expect(result.shortcutNumber, 1);
    });
  });
}

SearchTreeViewModel _build(
  List<SearchNode> nodes, {
  Set<String> collapsedIds = const {},
}) {
  return buildSearchTreeViewModel(
    nodes: nodes,
    isCollapsed: collapsedIds.contains,
  );
}
