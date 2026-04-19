import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../test_utils.dart";

void main() {
  group("QueryBar suggestions", () {
    testWidgets("shows selector key suggestions", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "sta");
      await tester.pump();

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsOneWidget);
      expect(find.text("status:"), findsOneWidget);
    });

    testWidgets("shows selector value suggestions", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "status:a");
      await tester.pump();

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsOneWidget);
      expect(find.text("active"), findsOneWidget);
      expect(find.text("archived"), findsOneWidget);
    });

    testWidgets("shows operator suggestions in operator context", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "AND",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final popupFinder = find.byKey(const ValueKey("query_bar_suggestions"));
      expect(popupFinder, findsOneWidget);
      expect(
        find.descendant(of: popupFinder, matching: find.text("AND")),
        findsOneWidget,
      );
      expect(find.text("Operator"), findsWidgets);
    });

    testWidgets("Enter applies first suggestion when no active selection", (
      tester,
    ) async {
      var latestQuery = "";
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (value) => latestQuery = value,
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "sta");
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(latestQuery, "status:");
      expect(editable.controller.text, "status:");
    });

    testWidgets("applying a suggestion uses replacement range", (tester) async {
      var latestQuery = "";
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (value) => latestQuery = value,
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "status:a");
      await tester.pump();

      await tester.tap(find.text("active"));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(latestQuery, "status:active");
      expect(editable.controller.text, "status:active");
      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsOneWidget);
    });
  });

  group("QueryBar keyboard", () {
    testWidgets("arrow keys navigate and Enter applies active suggestion", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "s");
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "source:");
    });

    testWidgets("control navigation shortcuts work with suggestion list", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "s");
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "status:");
    });

    testWidgets("Escape dismisses visible suggestions", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "sta");
      await tester.pump();

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);
    });

    testWidgets("no shortcut overrides are active without suggestions", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "zzz");
      await tester.pump();

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "zzz");
    });
  });

  group("QueryBar highlighting", () {
    testWidgets("highlights selector keys and values", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "title:Book hello",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      final editableFinder = find.byType(EditableText);
      final editable = tester.widget<EditableText>(editableFinder);
      final context = tester.element(editableFinder);
      final span = editable.controller.buildTextSpan(
        context: context,
        withComposing: false,
        style: editable.style,
      );

      final titleStyles = _stylesForText(span, "title");
      final valueStyles = _stylesForText(span, "Book");
      final theme = Theme.of(context);

      expect(titleStyles, isNotEmpty);
      expect(valueStyles, isNotEmpty);
      expect(titleStyles.first?.color, theme.colorScheme.primary);
      expect(valueStyles.first?.color, theme.colorScheme.secondary);
    });

    testWidgets("issue styles override token styles", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "id:1 id:2",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      final editableFinder = find.byType(EditableText);
      final editable = tester.widget<EditableText>(editableFinder);
      final context = tester.element(editableFinder);
      final span = editable.controller.buildTextSpan(
        context: context,
        withComposing: false,
        style: editable.style,
      );

      final idStyles = _stylesForText(span, "id");
      final theme = Theme.of(context);

      expect(idStyles.length, greaterThanOrEqualTo(2));
      expect(idStyles.first?.color, theme.colorScheme.primary);
      expect(idStyles.last?.color, theme.colorScheme.error);
      expect(idStyles.last?.decoration, TextDecoration.underline);
    });
  });
}

List<TextStyle?> _stylesForText(TextSpan root, String text) {
  return _leafTextSpans(root)
      .where((span) => span.text == text)
      .map((span) => span.style)
      .toList(growable: false);
}

List<TextSpan> _leafTextSpans(TextSpan root) {
  final output = <TextSpan>[];

  void visit(InlineSpan span) {
    if (span is! TextSpan) {
      return;
    }

    final children = span.children;
    if (children == null || children.isEmpty) {
      output.add(span);
      return;
    }

    for (final child in children) {
      visit(child);
    }
  }

  visit(root);
  return output;
}
