import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("a row with interactive content", () {
    testWidgets("a click on that content activates the row instead", (
      tester,
    ) async {
      var rowActivations = 0;
      var innerActivations = 0;
      final panel = await tester.pumpPanel(
        const [],
        // A dropdown gives its rows a bounded width.
        at: PanelLocation.component(
          SizedBox(
            width: 360,
            child: SearchResultRow(
              row: searchRowContext(onTap: () => rowActivations++),
              density: SearchResultDensity.card,
              title: "Resource",
              leading: const Icon(Icons.book),
              kindLabel: "book",
              body: TextButton(
                onPressed: () => innerActivations++,
                child: const Text("Inner action"),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.text("Inner action")));
      await panel.settle();

      expect(rowActivations, 1);
      expect(innerActivations, 0);
    });

    testWidgets("Tab reaches the row but never that content", (tester) async {
      var rowActivations = 0;
      var innerActivations = 0;
      final panel = await tester.pumpPanel(
        const [],
        // A dropdown gives its rows a bounded width.
        at: PanelLocation.component(
          SizedBox(
            width: 360,
            child: SearchResultRow(
              row: searchRowContext(onTap: () => rowActivations++),
              density: SearchResultDensity.card,
              title: "Resource",
              leading: const Icon(Icons.book),
              kindLabel: "book",
              body: TextButton(
                onPressed: () => innerActivations++,
                child: const Text("Inner action"),
              ),
            ),
          ),
        ),
      );

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.search.result("Resource").isFocused, isTrue);

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, isNot("Inner action"));
    });
  });

  testWidgets("a busy row shows its work beside its kind and shortcut", (
    tester,
  ) async {
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 360,
          child: ValueListenableBuilder(
            valueListenable: busy,
            builder: (context, loading, _) => SearchResultRow(
              row: searchRowContext(loading: loading),
              density: SearchResultDensity.card,
              kindLabel: "page",
              title: "Meet the Mayor",
            ),
          ),
        ),
      ),
    );

    // The spinner never settles, so the row turns busy after the panel did.
    busy.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(panel.search.result("Meet the Mayor").lines, [
      searchResultWorkingSemanticLabel,
      "Meet the Mayor",
      "PAGE",
      "1",
    ]);
  });

  for (final density in SearchResultDensity.values) {
    testWidgets(
      "a ${density.name} result takes its name, accent and icon from the appearance",
      (tester) async {
        final operations = PortableOperationResults();
        addTearDown(operations.dispose);
        const accent = Color(0xff3f51b5);
        final icon = skir.Icon.wrapIconify("material-symbols:book");
        final panel = await tester.pumpPanel(
          const [],
          at: PanelLocation.component(
            SizedBox(
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
                row: searchRowContext(),
                density: density,
                appearance: skir.ResourceAppearance(
                  label: "Main story",
                  accent: accent.toSkirColor(),
                  icon: icon,
                ),
                kindLabel: "Book",
              ),
            ),
          ),
        );

        final row = panel.search.result("Main story");
        expect(row.lines, containsAll(["Main story", "BOOK"]));
        expect(panel.shows("Act one"), isTrue);
        expect(
          row.rect.height,
          density == SearchResultDensity.card
              ? greaterThanOrEqualTo(64)
              : lessThan(64),
        );
        // The accent and icon only show as pixels, so they are read from the
        // widgets that paint them.
        expect(
          tester.widget<ResourceIcon>(find.byType(ResourceIcon)).icon,
          icon,
        );
        if (density == SearchResultDensity.card) {
          expect(
            tester
                .widget<SearchResultCard>(find.byType(SearchResultCard))
                .color,
            accent,
          );
        }
      },
    );
  }

  testWidgets("a result without details shows only its name and kind", (
    tester,
  ) async {
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 360,
          child: PortableResultContent(
            node: presentationColumn("details", const []),
            scope: PortablePresentationScope(
              bindings: const {},
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              operations: operations,
            ),
            row: searchRowContext(),
            density: SearchResultDensity.card,
            appearance: skir.ResourceAppearance(
              label: "Lost tag",
              accent: const Color(0xff9e9e9e).toSkirColor(),
              icon: skir.Icon.wrapIconify("material-symbols:book"),
            ),
            kindLabel: "Tag",
          ),
        ),
      ),
    );

    expect(panel.search.result("Lost tag").lines, ["Lost tag", "TAG", "1"]);
  });
}
