import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "native row owns activation and excludes decorative controls from focus",
    (tester) async {
      var rowActivations = 0;
      var innerActivations = 0;
      final row = _row(onTap: () => rowActivations++);
      await tester.pumpTestApp(
        child: SearchResultRow(
          row: row,
          density: SearchResultDensity.card,
          accent: Colors.purple,
          leading: const Icon(Icons.book),
          kindLabel: "book",
          body: TextButton(
            onPressed: () => innerActivations++,
            child: const Text("Inner action"),
          ),
        ),
      );
      expect(find.byType(SearchResultCard), findsOneWidget);
      final card = tester.widget<SearchResultCard>(
        find.byType(SearchResultCard),
      );
      expect(card.selected, isTrue);
      expect(card.focused, isTrue);
      expect(card.color, Colors.purple);
      expect(
        Focus.of(tester.element(find.text("Inner action"))).canRequestFocus,
        isFalse,
      );
      await tester.tapAt(tester.getCenter(find.text("Inner action")));
      await tester.pump();
      expect(rowActivations, 1);
      expect(innerActivations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("busy native row preserves one icon tile and shortcut suffix", (
    tester,
  ) async {
    await tester.pumpTestApp(
      settle: false,
      child: SearchResultRow(
        row: _row(loading: true),
        density: SearchResultDensity.card,
        kindLabel: "page",
        title: "Meet the Mayor",
      ),
    );
    expect(find.byType(SearchResultIconTile), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final suffix = tester.widget<SearchResultSuffix>(
      find.byType(SearchResultSuffix),
    );
    expect(
      suffix.shortcutActivator,
      const SingleActivator(LogicalKeyboardKey.enter),
    );
    expect(suffix.label, "page");
    expect(suffix.selected, isTrue);
  });

  for (final density in SearchResultDensity.values) {
    testWidgets(
      "a ${density.name} result takes its name, accent and icon from the appearance",
      (tester) async {
        final operations = PortableOperationResults();
        addTearDown(operations.dispose);
        const accent = Color(0xff3f51b5);
        final icon = skir.Icon.wrapIconify("material-symbols:book");
        await tester.pumpTestApp(
          // A dropdown gives its rows a bounded width.
          child: SizedBox(
            width: 360,
            child: PortableResultContent(
              node: presentationText("details", textLiteral("Act one")),
              scope: PortablePresentationScope(
                bindings: const {},
                budget: skir.EvaluationBudget(
                  maxSteps: 100,
                  maxCollectionItems: 100,
                ),
                operations: operations,
              ),
              row: _row(),
              density: density,
              appearance: ResourceAppearance(
                label: "Main story",
                accent: accent,
                icon: icon,
              ),
              kindLabel: "Book",
            ),
          ),
        );
        final card = find.byType(SearchResultCard);
        if (density == SearchResultDensity.card) {
          expect(card, findsOneWidget);
          expect(tester.widget<SearchResultCard>(card).color, accent);
        } else {
          expect(card, findsNothing);
          expect(find.byType(ListTile), findsOneWidget);
        }
        expect(find.text("Main story"), findsOneWidget);
        expect(find.text("Act one"), findsOneWidget);
        expect(
          tester.widget<ResourceIcon>(find.byType(ResourceIcon)).icon,
          icon,
        );
        expect(
          tester
              .widget<SearchResultSuffix>(find.byType(SearchResultSuffix))
              .label,
          "Book",
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("a result without details shows only the host chrome", (
    tester,
  ) async {
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    await tester.pumpTestApp(
      child: PortableResultContent(
        node: presentationColumn("details", const []),
        scope: PortablePresentationScope(
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          operations: operations,
        ),
        row: _row(),
        density: SearchResultDensity.card,
        appearance: ResourceAppearance(
          label: "Lost tag",
          accent: const Color(0xff9e9e9e),
          icon: skir.Icon.wrapIconify("material-symbols:book"),
        ),
        kindLabel: "Tag",
      ),
    );
    expect(find.text("Lost tag"), findsOneWidget);
    expect(find.byType(PortablePresentationNodeRenderer), findsNothing);
  });
}

SearchResultRowContext _row({VoidCallback? onTap, bool loading = false}) =>
    SearchResultRowContext(
      result: const SearchResult(
        id: "resource",
        payload: "resource",
        type: SearchResultType(id: "test", rowRendererId: "test"),
      ),
      selected: true,
      focused: true,
      loading: loading,
      onTap: onTap,
      shortcutActivator: const SingleActivator(LogicalKeyboardKey.enter),
    );
