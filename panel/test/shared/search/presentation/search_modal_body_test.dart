import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final body = SearchBody(
    searchHint: "Search",
    rowRenderers: searchRows(
      density: SearchResultDensity.card,
      kindLabel: "Test",
    ),
  );

  testWidgets("a result shows through the renderer of its type", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );

    await panel.search.show(source, [resultNode("alpha")]);

    expect(panel.search.result("Result alpha").isShown, isTrue);
  });

  testWidgets("a result without a renderer names the missing renderer", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: const SearchBody(searchHint: "Search", rowRenderers: {}),
      size: const Size(800, 700),
    );

    await panel.search.show(source, [resultNode("alpha")]);

    expect(panel.shows("alpha"), isTrue);
    expect(panel.shows("Missing renderer test-row"), isTrue);
  });

  testWidgets("clicking a result selects it", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha")]);
    final alpha = panel.search.result("Result alpha");
    expect(alpha.isSelected, isFalse);

    await alpha.tap();

    expect(alpha.isSelected, isTrue);
  });

  testWidgets("Space toggles the selection of the focused result", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);
    final beta = panel.search.result("Result beta");
    await beta.focus();

    await panel.press(LogicalKeyboardKey.space);
    expect(beta.isSelected, isTrue);
    expect(panel.search.result("Result alpha").isSelected, isFalse);

    await panel.press(LogicalKeyboardKey.space);
    expect(beta.isSelected, isFalse);
  });

  for (final number in [1, 3, 9]) {
    testWidgets("the shortcut with digit $number opens result $number", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final activated = <String>[];
      final panel = await tester.showSearch(
        source,
        results: body,
        activated: activated,
        size: const Size(800, 700),
      );
      await panel.search.show(source, [
        for (var i = 1; i <= 10; i++) resultNode("item$i"),
      ]);

      await panel.search.activateByShortcut(number);

      expect(activated, ["item$number"]);
    });
  }

  testWidgets("shows progress while the first results load", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );

    source.emitSnapshot(SearchSourceSnapshot.loading());
    await tester.pump();

    expect(panel.shows(searchLoadingSemanticLabel), isTrue);
  });

  testWidgets("keeps stale results without showing first load progress", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );

    source.emitSnapshot(
      SearchSourceSnapshot.loading(
        nodes: [
          SearchNode.result(
            result: searchResult("alpha").copyWith(isStale: true),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(Duration.zero);

    expect(panel.shows(searchLoadingSemanticLabel), isFalse);
    expect(panel.search.result("Result alpha").isShown, isTrue);
  });
}
