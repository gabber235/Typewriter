import "package:flutter/material.dart" hide SearchController;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/search/presentation/search_result_renderers.dart";
import "package:typewriter_panel/shared/search/presentation/search_root.dart";
import "package:typewriter_panel/shared/search/presentation/search_tree_results.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";

import "../../../support/test_utils.dart";
import "../application/core/support/search_core_test_harness.dart";

void main() {
  group("SearchTreeResults", () {
    testWidgets("renders section title, nested result title, and muted count", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [resultNode("alpha"), resultNode("beta")],
            ),
          ],
        ),
      );

      expect(find.text("Books"), findsOneWidget);
      expect(find.text("Result alpha"), findsOneWidget);
      final count = tester.widget<Text>(find.text("(2)"));
      final colorScheme = Theme.of(
        tester.element(find.text("(2)")),
      ).colorScheme;
      expect(count.style!.color, colorScheme.onSurfaceVariant);
    });

    testWidgets("starts expanded", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [resultNode("alpha")],
            ),
          ],
        ),
      );

      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("tapping a section hides and shows descendants", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [resultNode("alpha")],
            ),
          ],
        ),
      );

      await tester.tap(find.text("Books"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("Books"), findsOneWidget);
      expect(find.text("Result alpha"), findsNothing);

      await tester.tap(find.text("Books"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("collapsed top level header stays visible", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [resultNode("alpha")],
            ),
          ],
        ),
      );

      await tester.tap(find.text("Books"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("Books"), findsOneWidget);
      expect(find.text("Result alpha"), findsNothing);
    });

    testWidgets("collapsed nested header stays visible", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [
                SearchNode.section(
                  id: "chapters",
                  title: "Chapters",
                  children: [resultNode("alpha")],
                ),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.text("Chapters"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("Books"), findsOneWidget);
      expect(find.text("Chapters"), findsOneWidget);
      expect(find.text("Result alpha"), findsNothing);
    });

    testWidgets("collapsed nested header can expand again", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [
                SearchNode.section(
                  id: "chapters",
                  title: "Chapters",
                  children: [resultNode("alpha")],
                ),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.text("Chapters"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(find.text("Chapters"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text("Chapters"), findsOneWidget);
      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("section chevron uses animated rotation", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [SearchNode.section(id: "books", title: "Books")],
        ),
      );

      expect(find.byType(AnimatedRotation), findsOneWidget);
    });

    testWidgets("missing renderer fallback appears", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.text("Missing renderer test-row"), findsOneWidget);
    });

    testWidgets("first visible result gets shortcut and tenth does not", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final contexts = <String, SearchResultRowContext>{};

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(
          source: source,
          rowRenderers: {
            "test-row": (context) {
              contexts[context.result.id] = context;
              return ListTile(title: Text(context.result.id));
            },
          },
        ),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [for (var i = 1; i <= 10; i++) resultNode("item$i")],
        ),
      );

      expect(contexts["item1"]!.shortcutActivator, isNotNull);
      expect(contexts["item10"]!.shortcutActivator, isNull);
    });

    testWidgets("builds a custom scroll view", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets("builds one sliver for each top level group", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(id: "books", title: "Books"),
            SearchNode.section(id: "pages", title: "Pages"),
          ],
        ),
      );

      expect(find.byType(SearchTreeSectionSliver), findsNWidgets(2));
    });

    testWidgets("top level headers are pinned", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [SearchNode.section(id: "books", title: "Books")],
        ),
      );

      expect(
        find.ancestor(
          of: find.text("Books"),
          matching: find.byType(PinnedHeaderSliver),
        ),
        findsOneWidget,
      );
    });

    testWidgets("nested section headers are not pinned", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [SearchNode.section(id: "nested", title: "Nested")],
            ),
          ],
        ),
      );

      expect(
        find.ancestor(
          of: find.text("Nested"),
          matching: find.byType(PinnedHeaderSliver),
        ),
        findsNothing,
      );
    });

    testWidgets("top level header remains visible while scrolling", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [for (var i = 1; i <= 30; i++) resultNode("item$i")],
            ),
          ],
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpSearchRows();

      expect(find.text("Books").hitTestable(), findsOneWidget);
    });

    testWidgets("tapping a pinned header toggles its body", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [
            SearchNode.section(
              id: "books",
              title: "Books",
              children: [resultNode("alpha")],
            ),
          ],
        ),
      );

      await tester.tap(find.text("Books"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("Result alpha"), findsNothing);

      await tester.tap(find.text("Books"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("loading snapshot with no rows shows shimmer", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(tester, SearchSourceSnapshot.loading());

      expect(find.byType(ShimmerBox), findsWidgets);
      expect(find.text("No results found"), findsNothing);
    });

    testWidgets("ready snapshot with no rows shows empty state", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        SearchSourceSnapshot.ready(nodes: const []),
      );

      expect(find.text("No results found"), findsOneWidget);
    });

    testWidgets("idle snapshot with guidance shows guidance title", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        SearchSourceSnapshot.idle(
          guidance: const [
            SearchGuidance(
              id: "start",
              title: "Start typing",
              description: "Search by title",
            ),
          ],
        ),
      );

      expect(find.text("Start typing"), findsOneWidget);
    });

    testWidgets("error snapshot shows the error message", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        SearchSourceSnapshot.error(
          errorSummaries: const [
            SearchErrorSummary(
              id: "broken",
              message: "Search source failed",
              severity: SearchErrorSeverity.error,
              sourceLabel: "Test source",
            ),
          ],
        ),
      );

      expect(find.text("Search source failed"), findsOneWidget);
      expect(find.text("Test source"), findsOneWidget);
    });

    testWidgets("populated snapshot does not show empty state", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchTree(source: source, rowRenderers: _rowRenderers),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.text("No results found"), findsNothing);
      expect(find.text("Result alpha"), findsOneWidget);
    });
  });
}

final _rowRenderers = <String, SearchResultRowBuilder>{
  "test-row": (context) => ListTile(
    title: Text("Result ${context.result.id}"),
    selected: context.selected,
    onTap: context.onTap,
  ),
};

class _TestSearchTree extends StatelessWidget {
  const _TestSearchTree({required this.source, this.rowRenderers = const {}});

  final FakeSearchSource source;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: 500,
      child: SearchRoot(
        create: (ref) => SearchController(
          source: source,
          baseSelectors: const [
            KeyValueSelectorDefinition(id: "tag", key: "#"),
          ],
        ),
        child: SearchTreeResults(rowRenderers: rowRenderers),
      ),
    );
  }
}
