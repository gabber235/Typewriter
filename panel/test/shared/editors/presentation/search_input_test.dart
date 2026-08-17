import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "search_input_test_harness.dart";

void main() {
  testWidgets("pointer activation focuses and selects the current query", (
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

    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester
          .widget<QueryBar>(find.byType(QueryBar))
          .inputFieldController!
          .inputFocusNode
          .hasPrimaryFocus,
      isTrue,
    );
    final textFieldFinder = find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(TextFormField),
    );
    expect(textFieldFinder, findsOneWidget);
    final textField = tester.widget<TextFormField>(textFieldFinder);
    final editable = tester.widget<EditableText>(
      find.descendant(of: textFieldFinder, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasPrimaryFocus, isTrue);
    expect(tester.testTextInput.isRegistered, isTrue);
    expect(textField.controller!.text, "Alpha");
    expect(
      textField.controller!.selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );

    await tester.enterText(textFieldFinder, "Beta");
    await tester.pumpAndSettle();
    final resultRow = find.ancestor(
      of: find.text("Beta"),
      matching: find.byType(InkWell),
    );
    expect(resultRow, findsOneWidget);

    await tester.tap(resultRow);
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
    expect(find.text("Beta"), findsOneWidget);
  });

  testWidgets("explicit initial query overrides the selected value", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(initialQuery: "".asStringLiteral),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextFormField>(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(TextFormField),
      ),
    );
    expect(textField.controller!.text, isEmpty);
    expect(find.text("Beta"), findsOneWidget);
  });

  testWidgets("dismiss keeps the current preview", (tester) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(),
      ),
    );

    final container = tester.widget<InputFieldContainer>(
      find.byType(InputFieldContainer),
    );
    container.controller.requestSurroundingFocus();
    await tester.pump();
    Actions.invoke(
      tester.element(find.bySemanticsLabel("Activate search input")),
      const ActivateIntent(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    Actions.invoke(
      tester.element(find.byType(QueryBar)),
      const DismissIntent(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
    expect(find.text("Beta"), findsOneWidget);
  });

  testWidgets("cancel restores the interaction origin", (tester) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
    expect(find.text("Alpha"), findsOneWidget);
  });

  testWidgets("keyboard navigation commits the focused result", (tester) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final selected = find.byWidgetPredicate(
      (widget) => widget is Semantics && (widget.properties.selected ?? false),
    );
    expect(selected, findsOneWidget);
    expect(
      find.descendant(of: selected, matching: find.text("Beta")),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
    expect(find.text("Beta"), findsOneWidget);
  });

  testWidgets("boundary intents commit the first and last results", (
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
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text("Theta"), findsOneWidget);

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text("Alpha"), findsOneWidget);
  });

  testWidgets("multiple selection toggles immediately and traversal commits", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("Alpha")]),
        presentation: searchTestPresentation(multiple: true),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text("Beta"), matching: find.byType(InkWell))
          .first,
    );
    await tester.pump();

    expect(find.byType(QueryBar), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
    expect(find.text("2 items"), findsOneWidget);
  });

  testWidgets("result surface is bounded and internally scrollable", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(maximumExtent: 156),
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();

    final scrollable = find.byType(CustomScrollView).last;
    expect(tester.getSize(scrollable).height, lessThanOrEqualTo(156));
    expect(
      tester.widget<CustomScrollView>(scrollable).physics,
      isNot(const NeverScrollableScrollPhysics()),
    );
  });

  testWidgets("read only search input does not activate", (tester) async {
    await tester.pumpTestApp(
      child: searchTestRenderer(
        type: const StringType(),
        value: const StringValue("Alpha"),
        presentation: searchTestPresentation(),
        readOnly: true,
      ),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();

    expect(find.byType(QueryBar), findsNothing);
  });
}
