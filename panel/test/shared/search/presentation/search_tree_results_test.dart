import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("shows the section title, its results and a muted count", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", [resultNode("alpha"), resultNode("beta")]),
    ]);

    expect(panel.shows("Books"), isTrue);
    expect(panel.search.result("Result alpha").isShown, isTrue);
    expect(panel.search.result("Result beta").isShown, isTrue);
    final count = find.text("(2)");
    expect(
      tester.widget<Text>(count).style!.color,
      Theme.of(tester.element(count)).colorScheme.onSurfaceVariant,
    );
  });

  testWidgets("shows a header for each top level section", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", const []),
      sectionNode("Pages", const []),
    ]);

    expect(panel.shows("Books"), isTrue);
    expect(panel.shows("Pages"), isTrue);
  });

  testWidgets("clicking a section hides and shows its results", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", [resultNode("alpha")]),
    ]);

    await panel.search.toggleSection("Books");
    expect(panel.shows("Books"), isTrue);
    expect(panel.search.result("Result alpha").isShown, isFalse);

    await panel.search.toggleSection("Books");
    expect(panel.search.result("Result alpha").isShown, isTrue);
  });

  testWidgets("a collapsed nested section keeps its header and can reopen", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", [
        sectionNode("Chapters", [resultNode("alpha")]),
      ]),
    ]);

    await panel.search.toggleSection("Chapters");
    expect(panel.shows("Books"), isTrue);
    expect(panel.shows("Chapters"), isTrue);
    expect(panel.search.result("Result alpha").isShown, isFalse);

    await panel.search.toggleSection("Chapters");
    expect(panel.search.result("Result alpha").isShown, isTrue);
  });

  testWidgets("a top level header stays on screen while results scroll", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", [
        for (var i = 1; i <= 30; i++) resultNode("item$i"),
      ]),
    ]);

    await panel.search.result("Result item3").drag(const Offset(0, -400));

    expect(find.text("Books").hitTestable(), findsOneWidget);
  });

  testWidgets("a nested header scrolls away with its results", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [
      sectionNode("Books", [
        sectionNode("Chapters", [
          for (var i = 1; i <= 30; i++) resultNode("item$i"),
        ]),
      ]),
    ]);
    expect(find.text("Chapters").hitTestable(), findsOneWidget);

    await panel.search.result("Result item3").drag(const Offset(0, -400));

    expect(find.text("Books").hitTestable(), findsOneWidget);
    expect(find.text("Chapters").hitTestable(), findsNothing);
  });

  testWidgets("shows placeholders while the first results load", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);

    source.emitSnapshot(SearchSourceSnapshot.loading());
    // The placeholders shimmer until results arrive, so time is pumped
    // instead of settled.
    await tester.pump();

    expect(panel.shows(searchLoadingSemanticLabel), isTrue);
    expect(panel.shows("No results found"), isFalse);
  });

  testWidgets("a search without results says so", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, const []);

    expect(panel.shows("No results found"), isTrue);
  });

  testWidgets("an idle search shows the source's guidance", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);

    source.emitSnapshot(
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
    await panel.settle();

    expect(panel.shows("Start typing"), isTrue);
  });

  testWidgets("a failed search shows the error and the failing source", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);

    source.emitSnapshot(
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
    await panel.settle();

    expect(panel.shows("Search source failed"), isTrue);
    expect(panel.shows("Test source"), isTrue);
  });

  group("rows animate", () {
    testWidgets("a removed row stays until its exit finished", (tester) async {
      final source = FakeSearchSource();
      final panel = await tester.showSearch(source);
      await panel.search.show(source, [
        resultNode("alpha"),
        resultNode("beta"),
      ], settle: false);

      await panel.search.show(source, [resultNode("beta")], settle: false);
      expect(panel.search.result("Result alpha").isShown, isTrue);

      await panel.settle();
      expect(panel.search.result("Result alpha").isShown, isFalse);
    });

    testWidgets("an added row shows while it is still growing in", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final panel = await tester.showSearch(source);
      await panel.search.show(source, [resultNode("alpha")], settle: false);

      await panel.search.show(source, [
        resultNode("alpha"),
        resultNode("beta"),
      ], settle: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(panel.search.result("Result beta").isShown, isTrue);
    });

    testWidgets("collapsing a section lets its rows leave gradually", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final panel = await tester.showSearch(source);
      await panel.search.show(source, [
        sectionNode("Books", [resultNode("alpha")]),
      ], settle: false);

      await tester.tap(find.text("Books"));
      await tester.pump();

      expect(panel.search.result("Result alpha").isShown, isTrue);
    });

    testWidgets("removals and insertions together end in the new order", (
      tester,
    ) async {
      final source = FakeSearchSource();
      final panel = await tester.showSearch(source);
      await panel.search.show(source, [
        resultNode("alpha"),
        resultNode("beta"),
        resultNode("gamma"),
      ], settle: false);

      await panel.search.show(source, [
        resultNode("gamma"),
        resultNode("beta"),
        resultNode("delta"),
      ], settle: false);
      await panel.settle();

      expect(panel.search.result("Result alpha").isShown, isFalse);
      final tops = [
        for (final id in ["gamma", "beta", "delta"])
          panel.search.result("Result $id").rect.top,
      ];
      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));
    });
  });

  testWidgets("results replace the empty message", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.showSearch(source);
    await panel.search.show(source, [resultNode("alpha")]);

    expect(panel.shows("No results found"), isFalse);
    expect(panel.search.result("Result alpha").isShown, isTrue);
  });
}
