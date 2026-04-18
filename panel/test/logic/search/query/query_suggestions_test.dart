import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const SymbolSelectorDefinition(id: "tag", symbol: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title"),
    KeyValueSelectorDefinition(
      id: "role",
      key: "role",
      suggestionSource: (partial) => <String>["admin", "author", "member"],
    ),
  ];

  test("selector key context returns key and symbol suggestions", () {
    const context = SelectorKeyCursorContext(
      cursorOffset: 2,
      activeRange: QueryRange(0, 2),
      partialKey: "ti",
    );
    const result = QueryParseResult(
      expression: null,
      selectorMatches: <QuerySelectorMatch>[],
      textTerms: <QueryTextTerm>[],
      leftoverText: "",
      issues: <QueryParseIssue>[],
      cursorContext: context,
    );

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    expect(suggestions.whereType<SelectorKeySuggestion>().isNotEmpty, isTrue);
    expect(
      suggestions.any((suggestion) => suggestion.label == "title:"),
      isTrue,
    );
    expect(
      suggestions.every((suggestion) => suggestion.replaceRange.start == 0),
      isTrue,
    );
  });

  test("selector value context returns selector value suggestions", () {
    const context = SelectorValueCursorContext(
      cursorOffset: 7,
      activeRange: QueryRange(5, 7),
      selectorId: "role",
      partialValue: "ad",
      keyRange: QueryRange(0, 4),
      valueRange: QueryRange(5, 7),
    );
    const result = QueryParseResult(
      expression: null,
      selectorMatches: <QuerySelectorMatch>[],
      textTerms: <QueryTextTerm>[],
      leftoverText: "",
      issues: <QueryParseIssue>[],
      cursorContext: context,
    );

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    expect(suggestions.whereType<SelectorValueSuggestion>().isNotEmpty, isTrue);
    expect(
      suggestions.any((suggestion) => suggestion.label == "admin"),
      isTrue,
    );
  });

  test("operator context returns operator suggestions", () {
    const context = OperatorCursorContext(
      cursorOffset: 3,
      activeRange: QueryRange(3, 5),
      partialOperator: "a",
    );
    const result = QueryParseResult(
      expression: null,
      selectorMatches: <QuerySelectorMatch>[],
      textTerms: <QueryTextTerm>[],
      leftoverText: "",
      issues: <QueryParseIssue>[],
      cursorContext: context,
    );

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    expect(suggestions.whereType<OperatorSuggestion>().isNotEmpty, isTrue);
    expect(suggestions.any((suggestion) => suggestion.label == "AND"), isTrue);
    expect(
      suggestions.every((suggestion) => suggestion.replaceRange.start == 3),
      isTrue,
    );
  });

  test("max items limit is enforced", () {
    const context = OperatorCursorContext(
      cursorOffset: 0,
      activeRange: QueryRange(0, 0),
      partialOperator: "",
    );
    const result = QueryParseResult(
      expression: null,
      selectorMatches: <QuerySelectorMatch>[],
      textTerms: <QueryTextTerm>[],
      leftoverText: "",
      issues: <QueryParseIssue>[],
      cursorContext: context,
    );

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result, maxItems: 2);

    expect(suggestions, hasLength(2));
  });
}
