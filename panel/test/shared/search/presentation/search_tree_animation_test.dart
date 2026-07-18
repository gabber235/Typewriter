import "package:flutter/material.dart" hide SearchController;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/search/presentation/search_result_renderers.dart";
import "package:typewriter_panel/shared/search/presentation/search_root.dart";
import "package:typewriter_panel/shared/search/presentation/search_tree_results.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";

import "../../../support/test_utils.dart";
import "../application/core/support/search_core_test_harness.dart";

void main() {
  group("SearchTreeAnimatedBody", () {
    testWidgets("removed row remains visible during removal animation", (
      tester,
    ) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha"), resultNode("beta")]),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("beta")]),
      );

      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("removed row is gone after the animation duration", (
      tester,
    ) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha"), resultNode("beta")]),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("beta")]),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(Duration.zero);

      expect(find.text("Result alpha"), findsNothing);
    });

    testWidgets("added row appears during insertion animation", (tester) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha"), resultNode("beta")]),
      );

      expect(find.text("Result beta"), findsOneWidget);
    });

    testWidgets("collapsing a section animates descendant removal", (
      tester,
    ) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

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

      expect(find.text("Result alpha"), findsOneWidget);
    });

    testWidgets("expanding a section animates descendant insertion", (
      tester,
    ) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

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

    testWidgets("remove then insert changes do not throw index assertions", (
      tester,
    ) async {
      final source = FakeSearchSource();
      await _pumpTree(tester, source);

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [resultNode("alpha"), resultNode("beta"), resultNode("gamma")],
        ),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(
          nodes: [resultNode("gamma"), resultNode("beta"), resultNode("delta")],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpTree(WidgetTester tester, FakeSearchSource source) async {
  await tester.pumpTestApp(
    settle: false,
    child: SizedBox(
      width: 600,
      height: 500,
      child: SearchRoot(
        create: (ref) => SearchController(
          source: source,
          baseSelectors: const [
            KeyValueSelectorDefinition(id: "tag", key: "#"),
          ],
        ),
        child: SearchTreeResults(rowRenderers: _rowRenderers),
      ),
    ),
  );
}

final _rowRenderers = <String, SearchResultRowBuilder>{
  "test-row": (context) => ListTile(
    title: Text("Result ${context.result.id}"),
    onTap: context.onTap,
  ),
};
