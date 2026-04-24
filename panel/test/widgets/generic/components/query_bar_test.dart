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

    testWidgets("shows helper when query is empty", (tester) async {
      await tester.pumpTestApp(
        child: QueryBar(
          query: "",
          selectors: mockQuerySelectors,
          onQueryChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(TextField));
      await _pumpUi(tester);
      expect(_suggestions(), findsNothing);
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
      await _waitForSuggestionsVisible(tester);

      expect(find.textContaining("You can use:"), findsNothing);
      expect(_suggestions(), findsOneWidget);
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
      await _waitForHelperVisible(tester);

      expect(_suggestions(), findsNothing);
      expect(_helperBadges(), findsWidgets);

      await tester.enterText(find.byType(TextField), "status:a");
      await _waitForSuggestionsVisible(tester);

      expect(find.textContaining("You can use:"), findsNothing);
      expect(_suggestions(), findsOneWidget);
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
      await _waitForSuggestionsVisible(tester);
      final hostFinder = find.byKey(const ValueKey("query_bar_host"));
      final beforeHeight = tester.getSize(hostFinder).height;

      await _pumpUi(tester);
      final afterHeight = tester.getSize(hostFinder).height;

      expect(_suggestions(), findsOneWidget);
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
      await _waitForSuggestionsVisible(tester);

      final fieldRect = tester.getRect(find.byType(TextField));
      final popupRect = tester.getRect(_suggestions());
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
      await _pumpUi(tester);
      expect(_suggestions(), findsNothing);
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
      await _waitForHelperVisible(tester);

      expect(_helperBadgesWithPrefix("status"), findsOneWidget);
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
      await _waitForSuggestionsVisible(tester);

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
      await _waitForSuggestionsVisible(tester);

      await tester.tap(
        find.byKey(const ValueKey("query_bar_suggestion_0")).first,
      );
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(latestQuery, "status:active");
      expect(editable.controller.text, "status:active");
      expect(_suggestions(), findsOneWidget);
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
      await _waitForSuggestionsVisible(tester);

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
      await _waitForSuggestionsVisible(tester);

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
      await _waitForSuggestionsVisible(tester);

      expect(_suggestions(), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _waitForSuggestionsHidden(tester);

      expect(_suggestions(), findsNothing);
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
      await _waitForHelperVisible(tester);

      expect(_helperBadges(), findsWidgets);
      expect(_suggestions(), findsNothing);

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
          query: "status:active hello",
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

      final selectorStyles = _stylesForTextContaining(span, "status");
      final theme = Theme.of(context);
      final statusSelector = mockQuerySelectors
          .whereType<KeyValueSelectorDefinition>()
          .firstWhere((selector) => selector.id == "status");

      expect(selectorStyles, isNotEmpty);
      expect(
        selectorStyles.first?.color,
        statusSelector.color ?? theme.colorScheme.primary,
      );
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

      final idStyles = _stylesForTextContaining(span, "id");
      final theme = Theme.of(context);
      final idSelector = mockQuerySelectors
          .whereType<KeyValueSelectorDefinition>()
          .firstWhere((selector) => selector.id == "id");

      expect(idStyles.length, greaterThanOrEqualTo(2));
      expect(
        idStyles.first?.color,
        idSelector.color ?? theme.colorScheme.primary,
      );
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

List<TextStyle?> _stylesForTextContaining(TextSpan root, String text) {
  return _leafTextSpans(root)
      .where((span) => (span.text ?? "").contains(text))
      .map((span) => span.style)
      .toList(growable: false);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _waitForSuggestionsVisible(WidgetTester tester) async {
  await tester.pumpUntil(() {
    expect(_suggestions(), findsOneWidget);
  });
}

Future<void> _waitForSuggestionsHidden(WidgetTester tester) async {
  await tester.pumpUntil(() {
    expect(_suggestions(), findsNothing);
  });
}

Future<void> _waitForHelperVisible(WidgetTester tester) async {
  await tester.pumpUntil(() {
    expect(find.textContaining("You can use:"), findsOneWidget);
  });
}

Finder _suggestions() {
  return find.byKey(const ValueKey("query_bar_suggestions"));
}

Finder _helperBadges() {
  return _helperBadgesWithPrefix("");
}

Finder _helperBadgesWithPrefix(String labelPrefix) {
  final keyPrefix = "query_bar_helper_badge_$labelPrefix";
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) {
      return false;
    }

    return key.value.startsWith(keyPrefix);
  });
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
