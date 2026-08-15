import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "search_input_test_harness.dart";

void main() {
  testWidgets("results keep independent heights and center the focused row", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(
          maximumExtent: 180,
          provider: _mixedHeightProvider,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();

    final shortRow = _resultRow("Alpha");
    final tallRow = _resultRow("Beta");
    expect(
      tester.getSize(shortRow).height,
      lessThan(tester.getSize(tallRow).height),
    );

    for (var index = 0; index < 4; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }

    final focusedRow = _resultRow("Delta");
    final viewport = find.byType(CustomScrollView).last;
    expect(
      (tester.getCenter(focusedRow).dy - tester.getCenter(viewport).dy).abs(),
      lessThan(2),
    );
  });

  testWidgets("selected result uses the selection container background", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();

    final selected = find.byWidgetPredicate(
      (widget) => widget is Semantics && (widget.properties.selected ?? false),
    );
    expect(selected, findsOneWidget);
    final background = find.descendant(
      of: selected,
      matching: find.byType(AnimatedContainer),
    );
    final decoration = tester.widget<AnimatedContainer>(background).decoration;
    final context = tester.element(selected);

    expect(decoration, isA<BoxDecoration>());
    expect(
      (decoration! as BoxDecoration).color,
      context.colors.selectionContainer,
    );
  });
}

Finder _resultRow(String label) {
  return find
      .ancestor(of: find.text(label).first, matching: find.byType(InkWell))
      .first;
}

final _mixedHeightProvider = SearchProvider.merge(
  children: [
    SearchProvider.staticValues(
      values: const ListValue([
        StringValue("Alpha"),
      ]).asLiteral(const ListType(element: StringType())),
      result: searchTestResultMapping,
    ),
    SearchProvider.staticValues(
      values: const ListValue([
        StringValue("Beta"),
        StringValue("Gamma"),
        StringValue("Delta"),
        StringValue("Epsilon"),
        StringValue("Zeta"),
      ]).asLiteral(const ListType(element: StringType())),
      result: _tallResultMapping,
    ),
  ],
);

const _tallResultExpression = TypedExpression(
  resultType: StringType(),
  expression: BindingExpression(BindingReference(bindingId: BindingId(13))),
);

const _tallResultMapping = SearchResultMapping(
  bindingId: BindingId(13),
  key: _tallResultExpression,
  selectedValue: _tallResultExpression,
  presentation: PresentationNode(
    id: "tall_row",
    element: ColumnElement(
      spacing: 6,
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
      children: [
        PresentationNode(
          id: "title",
          element: TextElement(_tallResultExpression),
        ),
        PresentationNode(
          id: "subtitle",
          element: TextElement(_tallResultExpression),
        ),
        PresentationNode(
          id: "detail",
          element: TextElement(_tallResultExpression),
        ),
      ],
    ),
  ),
);
