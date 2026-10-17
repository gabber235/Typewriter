import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
        body: const Text("Meet the Mayor"),
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

  testWidgets(
    "portable appearance failures remain visible inside the same native shell",
    (tester) async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final node =
          (skir.PresentationNode.mutable()
                ..nodeId = "body"
                ..element = skir.PresentationElement.wrapText(
                  (skir.TextContent.mutable()
                        ..value = skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapStringValue("A resource"),
                        ))
                      .toFrozen(),
                ))
              .toFrozen();
      await tester.pumpTestApp(
        child: PortableResultContent(
          node: node,
          scope: PortablePresentationScope(
            bindings: const {},
            budget: skir.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            operations: operations,
          ),
          row: _row(),
          fallbackStyle: SearchResultDensity.compact,
          fallbackKindLabel: "resource",
          appearance: skir.ResultAppearance(
            leading: null,
            kindLabel: null,

            style: skir.ResultStyle.card,
            accent: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("invalid color"),
            ),
          ),
        ),
      );
      expect(find.byType(SearchResultCard), findsOneWidget);
      expect(find.text("A resource"), findsOneWidget);
      expect(
        find.text("The result accent must evaluate to a color"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
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
