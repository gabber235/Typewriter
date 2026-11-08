import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _duplicateQuerySelectors = <QuerySelectorDefinition>[
  KeyValueSelectorDefinition(id: "status_1", key: "status"),
  KeyValueSelectorDefinition(id: "status_2", key: "status"),
  KeyValueSelectorDefinition(id: "type", key: "type"),
];

const _sourceBackedSelectors = <QuerySelectorDefinition>[
  KeyValueSelectorDefinition(
    id: "page",
    key: "page:",
    value: QuerySelectorValue.sourceBacked(),
  ),
];

/// The colors of the light theme the panel opens in.
final _colors = buildTheme(Brightness.light).colorScheme;

void main() {
  group("suggestions", () {
    testWidgets("a click focuses the query field", (tester) async {
      final bar = await tester.showQueryBar();

      await bar.focus();

      expect(bar.isFocused, isTrue);
    });

    testWidgets("a selector key offers the values matching its partial", (
      tester,
    ) async {
      final bar = await tester.showQueryBar();

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));

      expect(bar.showsHelper, isFalse);
      expect(bar.suggestions, ["active", "archived"]);
    });

    testWidgets("a source backed completion waits until typing pauses", (
      tester,
    ) async {
      final requests = <SearchSelectorCompletionRequest>[];
      final bar = await tester.showQueryBar(
        selectors: _sourceBackedSelectors,
        completeSelector: (request) async {
          requests.add(request);
          return const SearchSelectorCompletionResult(values: ["arrival"]);
        },
      );
      await bar.type("page:a");
      await tester.pump(const Duration(milliseconds: 100));
      await bar.type("page:ar");
      await tester.pump(const Duration(milliseconds: 149));

      expect(requests, isEmpty);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();

      expect(requests.map((request) => request.partial), ["ar"]);
      expect(bar.suggestions, ["arrival"]);
    });

    testWidgets("an answer for an older partial is ignored", (tester) async {
      final completions = <Completer<SearchSelectorCompletionResult>>[];
      final bar = await tester.showQueryBar(
        selectors: _sourceBackedSelectors,
        completeSelector: (_) {
          final completion = Completer<SearchSelectorCompletionResult>();
          completions.add(completion);
          return completion.future;
        },
      );
      await bar.type("page:a");
      await tester.pump(const Duration(milliseconds: 151));
      await bar.type("page:b");
      await tester.pump(const Duration(milliseconds: 151));
      expect(completions, hasLength(2));

      completions.first.complete(
        const SearchSelectorCompletionResult(values: ["arrival"]),
      );
      await tester.pump();
      expect(bar.suggestions, isNot(contains("arrival")));

      completions.last.complete(
        const SearchSelectorCompletionResult(values: ["bravo"]),
      );
      await tester.pumpAndSettle();
      expect(bar.suggestions, ["bravo"]);
    });

    testWidgets("the helper line gives way to suggestions", (tester) async {
      final bar = await tester.showQueryBar();

      await bar.focus();
      await tester.eventually(() => expect(bar.showsHelper, isTrue));
      expect(bar.showsSuggestions, isFalse);
      expect(bar.helperMentions("status:"), 1);

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));

      expect(bar.showsHelper, isFalse);
    });

    testWidgets("opening suggestions keeps the query bar's height", (
      tester,
    ) async {
      final bar = await tester.showQueryBar(query: "status:a");
      final before = bar.rect.height;

      await bar.focus();
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));

      expect(bar.rect.height, before);
    });

    testWidgets("suggestions are as wide as the query field", (tester) async {
      final bar = await tester.showQueryBar(width: 420);

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));

      expect(bar.suggestionsRect.width, closeTo(bar.rect.width, 4.1));
    });

    testWidgets("an operator offers no suggestions", (tester) async {
      final bar = await tester.showQueryBar(query: "AND");

      await bar.focus();
      await tester.pump(const Duration(milliseconds: 400));

      expect(bar.showsSuggestions, isFalse);
    });

    testWidgets("the helper names selectors that share a label once", (
      tester,
    ) async {
      final bar = await tester.showQueryBar(
        selectors: _duplicateQuerySelectors,
      );

      await bar.focus();
      await tester.eventually(() => expect(bar.showsHelper, isTrue));

      expect(bar.helperMentions("status"), 1);
    });

    testWidgets("Enter applies the first suggestion when none is active", (
      tester,
    ) async {
      var latestQuery = "";
      final bar = await tester.showQueryBar(
        onQueryChanged: (value) => latestQuery = value,
      );

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));
      await bar.submit();

      expect(latestQuery, "status:active");
      expect(bar.text, "status:active");
    });

    testWidgets("a chosen suggestion replaces only the partial it completes", (
      tester,
    ) async {
      var latestQuery = "";
      final bar = await tester.showQueryBar(
        onQueryChanged: (value) => latestQuery = value,
      );

      await bar.type("hello status:a world", cursor: 14);
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));
      await bar.chooseSuggestion("active");

      expect(latestQuery, "hello status:active world");
      expect(bar.text, "hello status:active world");
    });
  });

  group("keyboard", () {
    testWidgets("Enter submits when no suggestions are shown", (tester) async {
      String? submitted;
      final bar = await tester.showQueryBar(
        selectors: const [],
        onSubmitted: (value) => submitted = value,
      );

      await bar.type("mdi:home");
      await bar.submit();

      expect(submitted, "mdi:home");
    });

    testWidgets("Escape dismisses the bar when no suggestions are shown", (
      tester,
    ) async {
      var dismissals = 0;
      final bar = await tester.showQueryBar(
        selectors: const [],
        onDismiss: () => dismissals++,
      );

      await bar.focus();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(dismissals, 1);
    });

    testWidgets("arrow keys move through suggestions and Enter applies one", (
      tester,
    ) async {
      final bar = await tester.showQueryBar();

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(bar.text, "status:archived");
    });

    testWidgets("Enter on a suggestion wins over the containing input", (
      tester,
    ) async {
      var containingActivations = 0;
      final bar = await tester.showQueryBar(
        textFieldActions: [
          ActionShortcut.intent(
            id: "containing_input_activate",
            label: "Activate input",
            description: "Activate the containing input",
            intent: ActivateIntent,
            priority: 1,
            run: ActionRun.press((_) => containingActivations++),
          ),
        ],
      );

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(bar.text, "status:active");
      expect(containingActivations, 0);
    });

    testWidgets("Control N and P move through suggestions", (tester) async {
      final bar = await tester.showQueryBar();

      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(bar.text, "status:active");
    });

    testWidgets("Escape closes the suggestions", (tester) async {
      final bar = await tester.showQueryBar();
      await bar.type("status:a");
      await tester.eventually(() => expect(bar.showsSuggestions, isTrue));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      await tester.eventually(() => expect(bar.showsSuggestions, isFalse));
    });

    testWidgets("arrows and Enter leave the text alone in helper mode", (
      tester,
    ) async {
      final bar = await tester.showQueryBar();
      await bar.focus();
      await tester.eventually(() => expect(bar.showsHelper, isTrue));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(bar.showsSuggestions, isFalse);
      expect(bar.text, "");
    });
  });

  testWidgets("changing selectors keeps the text and cursor", (tester) async {
    final selectors = ValueNotifier(mockQuerySelectors);
    addTearDown(selectors.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 500,
          child: ValueListenableBuilder(
            valueListenable: selectors,
            builder: (context, current, _) =>
                QueryBar(query: "", selectors: current, onQueryChanged: (_) {}),
          ),
        ),
      ),
    );
    final bar = panel.queryBar;
    await bar.type("main");
    expect(bar.selection, const TextSelection.collapsed(offset: 4));

    selectors.value = [
      ...mockQuerySelectors,
      const KeyValueSelectorDefinition(id: "book", key: "book:"),
    ];
    await tester.pump();

    expect(bar.text, "main");
    expect(bar.selection, const TextSelection.collapsed(offset: 4));
  });

  group("highlighting", () {
    testWidgets("a selector's key and value take its color", (tester) async {
      final bar = await tester.showQueryBar(query: "status:active hello");
      final color = mockQuerySelectorColor("status") ?? _colors.primary;

      expect(bar.stylesOf("status").first?.color, color);
      expect(bar.stylesOf("active").first?.color, color);
      expect(bar.stylesOf("hello").first?.color, isNot(color));
    });

    testWidgets("an issue's style wins over the selector's color", (
      tester,
    ) async {
      final bar = await tester.showQueryBar(query: "id:1 id:2");
      final error = buildTheme(Brightness.light).colors.dangerText;

      final idStyles = bar.stylesOf("id");
      expect(idStyles, hasLength(greaterThanOrEqualTo(2)));
      expect(
        idStyles.first?.color,
        mockQuerySelectorColor("id") ?? _colors.primary,
      );
      expect(idStyles.last?.color, error);
      expect(idStyles.last?.decoration, TextDecoration.underline);
    });
  });
}
