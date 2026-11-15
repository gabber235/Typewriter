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

  testWidgets("clicking a result opens it", (tester) async {
    final source = FakeSearchSource();
    final activated = <String>[];
    final panel = await tester.showSearch(
      source,
      results: body,
      activated: activated,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);

    await panel.search.result("Result beta").tap();

    expect(activated, ["beta"]);
  });

  testWidgets("Down moves focus from the query to the first result, and Up "
      "back, with the search still open", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);
    expect(panel.queryBar.isFocused, isTrue);

    await panel.press(LogicalKeyboardKey.arrowDown);
    expect(panel.search.result("Result alpha").isFocused, isTrue);
    await panel.press(LogicalKeyboardKey.arrowDown);
    expect(panel.search.result("Result beta").isFocused, isTrue);

    await panel.press(LogicalKeyboardKey.arrowUp);
    await panel.press(LogicalKeyboardKey.arrowUp);
    expect(panel.queryBar.isFocused, isTrue);
  });

  testWidgets("typing on a focused result types into the query", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(
      source,
      results: body,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);
    await panel.queryBar.type("al");
    await panel.press(LogicalKeyboardKey.arrowDown);

    await panel.press(LogicalKeyboardKey.keyP);

    expect(panel.queryBar.isFocused, isTrue);
    expect(panel.queryBar.text, "alp");
  });

  testWidgets("Enter in the query opens the first result", (tester) async {
    final source = FakeSearchSource();
    final activated = <String>[];
    final panel = await tester.showSearch(
      source,
      results: body,
      activated: activated,
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.queryBar.isFocused, isTrue);

    await panel.press(LogicalKeyboardKey.enter);

    expect(activated, ["alpha"]);
  });

  testWidgets("a command's key acts on the focused result only", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final ran = <String>[];
    final command = SearchCommand.single<String>(
      id: const SearchCommandId("test.copy"),
      presentation: const SearchCommandPresentation(
        label: "Copy",
        shortcut: SingleActivator(LogicalKeyboardKey.keyC, alt: true),
      ),
      matcher: const SearchResultMatcher(testResultType),
      execute: (context, value, target) async {
        ran.add(target.result.id);
        return const SearchCommandResult.completed(
          surfaceEffect: SearchSurfaceEffect.refresh(),
        );
      },
    );
    final panel = await tester.showSearch(
      source,
      results: body,
      commands: [command],
      size: const Size(800, 700),
    );
    await panel.search.show(source, [resultNode("alpha"), resultNode("beta")]);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.escape);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await panel.press(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(ran, isEmpty);

    await panel.press(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await panel.press(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(ran, ["alpha"]);
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

  testWidgets(
    "the first load progress runs along the query field's bottom edge, clear "
    "of its rounded corners",
    (tester) async {
      final source = FakeSearchSource();
      await tester.showSearch(
        source,
        results: body,
        size: const Size(800, 700),
      );

      source.emitSnapshot(SearchSourceSnapshot.loading());
      await tester.pump();

      final bar = tester.getRect(
        find.descendant(
          of: find.byType(QueryBar),
          matching: find.byType(EditorTextField),
        ),
      );
      final progress = tester.getRect(find.byType(WorkingLine));
      final corner = tester
          .element(find.byType(QueryBar))
          .shapes
          .largeBorderRadius
          .topLeft
          .x;
      expect(progress.bottom, closeTo(bar.bottom, 0.5));
      expect(progress.left, greaterThanOrEqualTo(bar.left + corner));
      expect(progress.right, lessThanOrEqualTo(bar.right - corner));
    },
  );

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
