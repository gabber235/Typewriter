import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../test_utils.dart";

const _duplicateQuerySelectors = <QuerySelectorDefinition>[
  KeyValueSelectorDefinition(id: "status_1", key: "status"),
  KeyValueSelectorDefinition(id: "status_2", key: "status"),
  KeyValueSelectorDefinition(id: "type", key: "type"),
];

void main() {
  group("QueryBar suggestions", () {
    testWidgets("tap focuses query input", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets("shows helper for selector and operator suggestions", (
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
      await _pumpOverlay(tester);

      final helperFinder = find.byKey(const ValueKey("query_bar_helper"));
      final badgesFinder = find.byKey(
        const ValueKey("query_bar_helper_badges"),
      );

      expect(helperFinder, findsOneWidget);
      expect(find.text("You can use:"), findsOneWidget);
      expect(badgesFinder, findsOneWidget);
      expect(
        find.descendant(of: badgesFinder, matching: find.byType(Text)),
        findsWidgets,
      );
      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);
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
      await _pumpOverlay(tester);

      expect(find.byKey(const ValueKey("query_bar_helper")), findsNothing);
      expect(
        find.byKey(const ValueKey("query_bar_suggestions")),
        findsOneWidget,
      );
      expect(find.text("active"), findsOneWidget);
      expect(find.text("archived"), findsOneWidget);
    });

    testWidgets("switches from helper mode to popup mode", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await _pumpOverlay(tester);

      expect(find.byKey(const ValueKey("query_bar_helper")), findsOneWidget);
      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);

      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      expect(find.byKey(const ValueKey("query_bar_helper")), findsNothing);
      expect(
        find.byKey(const ValueKey("query_bar_suggestions")),
        findsOneWidget,
      );
    });

    testWidgets("suggestions do not change query bar host height", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: SizedBox(
          width: 500,
          child: Container(
            key: const ValueKey("query_bar_host"),
            child: QueryBar(
              query: "status:a",
              selectors: mockQuerySelectors,
              onQueryChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await _pumpOverlay(tester);
      final hostFinder = find.byKey(const ValueKey("query_bar_host"));
      final beforeHeight = tester.getSize(hostFinder).height;

      await _pumpOverlay(tester);
      final afterHeight = tester.getSize(hostFinder).height;

      expect(
        find.byKey(const ValueKey("query_bar_suggestions")),
        findsOneWidget,
      );
      expect(afterHeight, beforeHeight);
    });

    testWidgets("suggestions match query field width by default", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: SizedBox(
          width: 420,
          child: QueryBar(
            query: "",
            selectors: mockQuerySelectors,
            onQueryChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      final fieldRect = tester.getRect(find.byType(TextField));
      final popupRect = tester.getRect(
        find.byKey(const ValueKey("query_bar_suggestions")),
      );
      expect(popupRect.width, closeTo(fieldRect.width, 4.1));
    });

    testWidgets("hides popup in operator context", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "AND",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await _pumpOverlay(tester);

      final badgesFinder = find.byKey(
        const ValueKey("query_bar_helper_badges"),
      );

      expect(find.byKey(const ValueKey("query_bar_helper")), findsOneWidget);
      expect(badgesFinder, findsOneWidget);
      expect(
        find.descendant(of: badgesFinder, matching: find.text("AND")),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);
    });

    testWidgets("deduplicates helper badges by label", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: _duplicateQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await _pumpOverlay(tester);

      final badgesFinder = find.byKey(
        const ValueKey("query_bar_helper_badges"),
      );
      expect(badgesFinder, findsOneWidget);
      expect(
        find.descendant(of: badgesFinder, matching: find.text("status:")),
        findsOneWidget,
      );
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
      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(latestQuery, "status:active");
      expect(editable.controller.text, "status:active");
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
      await _pumpOverlay(tester);

      await tester.tap(
        find.byKey(const ValueKey("query_bar_suggestion_0")).first,
      );
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(latestQuery, "status:active");
      expect(editable.controller.text, "status:active");
      expect(
        find.byKey(const ValueKey("query_bar_suggestions")),
        findsOneWidget,
      );
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
      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "status:archived");
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
      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "status:active");
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
      await tester.enterText(find.byType(TextField), "status:a");
      await _pumpOverlay(tester);

      expect(
        find.byKey(const ValueKey("query_bar_suggestions")),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _pumpOverlay(tester);

      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);
    });

    testWidgets("no shortcut overrides are active in helper mode", (
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
      await _pumpOverlay(tester);

      expect(find.byKey(const ValueKey("query_bar_helper")), findsOneWidget);
      expect(find.byKey(const ValueKey("query_bar_suggestions")), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "");
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

Future<void> _pumpOverlay(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
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
