import "package:flutter/material.dart" hide SearchController;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/search/presentation/search_modal_body.dart";
import "package:typewriter_panel/shared/search/presentation/search_result_renderers.dart";
import "package:typewriter_panel/shared/search/presentation/search_root.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";

import "../../../support/test_utils.dart";
import "../application/core/support/search_core_test_harness.dart";

void main() {
  group("SearchModalBody", () {
    testWidgets("renderer map renders a result row", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchBody(
          source: source,
          rowRenderers: {
            "test-row": (context) => ListTile(
              title: Text("Rendered ${context.result.id}"),
              onTap: context.onTap,
            ),
          },
        ),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.text("Rendered alpha"), findsOneWidget);
    });

    testWidgets("missing renderer shows fallback text", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchBody(source: source),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.text("Missing renderer test-row"), findsOneWidget);
    });

    testWidgets("tapping result toggles selected state", (tester) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchBody(
          source: source,
          rowRenderers: {
            "test-row": (context) => ListTile(
              title: Text("Selected ${context.selected}"),
              onTap: context.onTap,
            ),
          },
        ),
      );

      await source.emitSnapshotAndPump(
        tester,
        readySnapshot(nodes: [resultNode("alpha")]),
      );

      expect(find.text("Selected false"), findsOneWidget);

      await tester.tap(find.text("Selected false"));
      await tester.pump();

      expect(find.text("Selected true"), findsOneWidget);
    });

    testWidgets("only the first nine results receive shortcuts", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final contexts = <String, SearchResultRowContext>{};

      await tester.pumpTestApp(
        settle: false,
        child: _TestSearchBody(
          source: source,
          rowRenderers: {
            "test-row": (context) {
              contexts[context.result.id] = context;
              return ListTile(
                title: Text(context.result.id),
                onTap: context.onTap,
              );
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
  });
}

class _TestSearchBody extends StatelessWidget {
  const _TestSearchBody({required this.source, this.rowRenderers = const {}});

  final FakeSearchSource source;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context) {
    return SearchRoot(
      create: (ref) => SearchController(
        source: source,
        baseSelectors: const [KeyValueSelectorDefinition(id: "tag", key: "#")],
      ),
      child: SearchModalBody(searchHint: "Search", rowRenderers: rowRenderers),
    );
  }
}
