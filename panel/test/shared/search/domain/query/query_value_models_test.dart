import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("query value models", () {
    test("lexer tokens support deep equality, copying, and matching", () {
      const selector = QueryLexerKeyValueSelectorToken(
        selectorId: "status",
        keyRange: QueryRange(0, 7),
        raw: "status:open",
        range: QueryRange(0, 11),
        value: "open",
        valueRange: QueryRange(7, 11),
      );
      const sameSelector = QueryLexerKeyValueSelectorToken(
        selectorId: "status",
        keyRange: QueryRange(0, 7),
        raw: "status:open",
        range: QueryRange(0, 11),
        value: "open",
        valueRange: QueryRange(7, 11),
      );
      const negation = QueryLexerToken.negation(
        token: selector,
        raw: "!status:open",
        range: QueryRange(0, 12),
        operatorRange: QueryRange(0, 1),
      );
      const operator = QueryLexerToken.operator(
        type: QueryLexerOperatorType.and,
        raw: "status:open AND status:open",
        range: QueryRange(0, 27),
        left: selector,
        right: selector,
        operatorRange: QueryRange(12, 15),
      );

      expect(selector, sameSelector);
      expect(selector.copyWith(value: "closed").value, "closed");
      expect(selector, isA<QueryLexerSelectorToken>());
      expect(_tokenLabel(selector), "selector");
      expect(_tokenLabel(negation), "negation");
      expect(_tokenLabel(operator), "operator");
    });

    test("cursor contexts support equality, copying, and matching", () {
      const context = SelectorValueCursorContext(
        cursorOffset: 8,
        activeRange: QueryRange(0, 8),
        selectorId: "status",
        partialValue: "o",
        keyRange: QueryRange(0, 7),
        valueRange: QueryRange(7, 8),
      );

      expect(
        context,
        const QueryCursorContext.selectorValue(
          cursorOffset: 8,
          activeRange: QueryRange(0, 8),
          selectorId: "status",
          partialValue: "o",
          keyRange: QueryRange(0, 7),
          valueRange: QueryRange(7, 8),
        ),
      );
      expect(context.copyWith(partialValue: "op").partialValue, "op");
      expect(_cursorLabel(context), "selectorValue");
      expect(
        _cursorLabel(
          const QueryCursorContext.selectorKey(
            cursorOffset: 1,
            activeRange: QueryRange(0, 1),
            partialKey: "s",
          ),
        ),
        "selectorKey",
      );
      expect(
        _cursorLabel(
          const QueryCursorContext.operator(
            cursorOffset: 1,
            activeRange: QueryRange(0, 1),
            partialOperator: "A",
          ),
        ),
        "operator",
      );
      expect(
        _cursorLabel(
          const QueryCursorContext.unknown(
            cursorOffset: 1,
            activeRange: QueryRange(0, 1),
            partial: "x",
            side: QuerySide.expression,
          ),
        ),
        "unknown",
      );
    });

    test("suggestions support equality, copying, and matching", () {
      const range = QueryRange(0, 1);
      const suggestion = SelectorValueSuggestion(
        label: "open",
        replaceRange: range,
        selectorId: "status",
        value: "open",
      );

      expect(
        suggestion,
        const QuerySuggestion.selectorValue(
          label: "open",
          replaceRange: range,
          selectorId: "status",
          value: "open",
        ),
      );
      expect(suggestion.copyWith(value: "closed").value, "closed");
      expect(
        _suggestionLabel(
          const QuerySuggestion.selectorKey(
            label: "status:",
            replaceRange: range,
            selectorId: "status",
          ),
        ),
        "selectorKey",
      );
      expect(_suggestionLabel(suggestion), "selectorValue");
      expect(
        _suggestionLabel(
          const QuerySuggestion.operator(
            label: "AND",
            replaceRange: range,
            operatorToken: "AND",
          ),
        ),
        "operator",
      );
    });

    test("selector expressions and values have deep value semantics", () {
      const selector = SearchParsedSelector(
        selectorId: "status",
        key: "status:",
        value: "open",
      );
      const leaf = SearchSelectorExpression.leaf(selector);
      const expression = SearchSelectorExpression.not(leaf);
      const value = EnumSelectorValue(["open", "closed"]);

      expect(expression, const SearchSelectorExpression.not(leaf));
      expect(_expressionLabel(leaf), "leaf");
      expect(_expressionLabel(expression), "not");
      expect(
        _expressionLabel(
          const SearchSelectorExpression.binary(
            operator: SearchSelectorOperator.and,
            left: leaf,
            right: leaf,
          ),
        ),
        "binary",
      );
      expect(value, const QuerySelectorValue.enumValue(["open", "closed"]));
      expect(
        value.copyWith(possibleValues: ["open"]),
        const QuerySelectorValue.enumValue(["open"]),
      );
      expect(_selectorValueLabel(value), "enum");
      expect(
        _selectorValueLabel(const QuerySelectorValue.freeText()),
        "freeText",
      );
    });
  });
}

String _tokenLabel(QueryLexerToken token) => switch (token) {
  QueryLexerKeyValueSelectorToken() => "selector",
  QueryLexerOperatorToken() => "operator",
  QueryLexerNegationToken() => "negation",
};

String _cursorLabel(QueryCursorContext context) => switch (context) {
  SelectorKeyCursorContext() => "selectorKey",
  SelectorValueCursorContext() => "selectorValue",
  OperatorCursorContext() => "operator",
  UnknownCursorContext() => "unknown",
};

String _suggestionLabel(QuerySuggestion suggestion) => switch (suggestion) {
  SelectorKeySuggestion() => "selectorKey",
  SelectorValueSuggestion() => "selectorValue",
  OperatorSuggestion() => "operator",
};

String _expressionLabel(SearchSelectorExpression expression) =>
    switch (expression) {
      SearchSelectorLeafExpression() => "leaf",
      SearchSelectorBinaryExpression() => "binary",
      SearchSelectorNotExpression() => "not",
    };

String _selectorValueLabel(QuerySelectorValue value) => switch (value) {
  FreeTextSelectorValue() => "freeText",
  EnumSelectorValue() => "enum",
};
