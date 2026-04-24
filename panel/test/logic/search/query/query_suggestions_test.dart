import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

import "query_test_harness.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
    const KeyValueSelectorDefinition(
      id: "role",
      key: "role:",
      value: QuerySelectorValue.enumValue(["admin", "author", "member"]),
    ),
    const KeyValueSelectorDefinition(
      id: "id",
      key: "id:",
      multiplicity: QueryMultiplicity.single,
    ),
  ];

  final engine = QuerySuggestionEngine(selectors);

  test(
    "selector key context returns key suggestions and replacement range",
    () {
      final result = checkQuery(
        "ti",
        selectors: selectors,
        cursorOffset: 2,
      ).expectNoIssues().expectNoExpression().expectQuery("ti").done();

      final suggestions = engine.suggest(result);
      final keySuggestions = suggestions
          .whereType<SelectorKeySuggestion>()
          .toList();

      expect(keySuggestions, hasLength(1));
      final keySuggestion = keySuggestions.first;
      expect(keySuggestion.selectorId, "title");
      expect(keySuggestion.replaceRange.start, 0);
      expect(keySuggestion.replaceRange.end, 2);
    },
  );

  test(
    "selector value context returns selector value suggestions and replacement range",
    () {
      final result =
          checkQuery("role:ad", selectors: selectors, cursorOffset: 7)
              .expectIssues([QueryIssueCode.invalidSelectorValue])
              .expectExpression(
                (token) => token.isSelector(id: "role", value: "ad"),
              )
              .expectNoQuery()
              .done();

      final suggestions = engine.suggest(result);
      final valueSuggestions = suggestions
          .whereType<SelectorValueSuggestion>()
          .toList();
      final adminSuggestion = valueSuggestions.firstWhere(
        (suggestion) => suggestion.value == "admin",
      );

      expect(valueSuggestions, isNotEmpty);
      expect(adminSuggestion.label, "admin");
      expect(adminSuggestion.selectorId, "role");
      expect(adminSuggestion.replaceRange, const QueryRange(5, 7));
    },
  );

  test("operator context returns operator suggestions", () {
    final result =
        checkQuery("#a AND #b", selectors: selectors, cursorOffset: 4)
            .expectNoIssues()
            .expectExpression(
              (token) => token.isAnd()
                ..left().isSelector(id: "tag", value: "a")
                ..right().isSelector(id: "tag", value: "b"),
            )
            .expectNoQuery()
            .done();

    final suggestions = engine.suggest(result);
    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();

    expect(operatorSuggestions, hasLength(1));
    final operatorSuggestion = operatorSuggestions.first;
    expect(operatorSuggestion.operatorToken, "AND");
    expect(operatorSuggestion.replaceRange.start, 3);
    expect(operatorSuggestion.replaceRange.end, 6);
  });

  test("! operator provides key suggestion directly after", () {
    final result = checkQuery("#a !ti", selectors: selectors, cursorOffset: 6)
        .expectNoIssues()
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .expectQuery("!ti")
        .done();

    final suggestions = engine.suggest(result);
    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test("max items limit is enforced", () {
    final result = checkQuery(
      "",
      selectors: selectors,
      cursorOffset: 0,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();

    final suggestions = engine.suggest(result, maxItems: 2);

    expect(suggestions, hasLength(2));
  });

  test("max items larger than result count returns all suggestions", () {
    final result = checkQuery("role:ad", selectors: selectors, cursorOffset: 7)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectExpression((token) => token.isSelector(id: "role", value: "ad"))
        .expectNoQuery()
        .done();

    final suggestions = engine.suggest(result, maxItems: 99);

    expect(suggestions, hasLength(1));
    expect(suggestions.single, isA<SelectorValueSuggestion>());
  });

  test("with other query text, key suggestion are returned", () {
    final result = checkQuery(
      "some text ti",
      selectors: selectors,
      cursorOffset: 12,
    ).expectNoIssues().expectQuery("some text ti").expectNoExpression().done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test("with leftover text, value suggestions are still returned", () {
    final result =
        checkQuery("some text role:ad", selectors: selectors, cursorOffset: 17)
            .expectIssues([QueryIssueCode.invalidSelectorValue])
            .expectQuery("some text")
            .expectExpression(
              (token) => token.isSelector(id: "role", value: "ad"),
            )
            .done();

    final suggestions = engine.suggest(result);

    final valueSuggestions = suggestions
        .whereType<SelectorValueSuggestion>()
        .toList();
    expect(valueSuggestions, hasLength(1));
    expect(valueSuggestions.first.selectorId, "role");
  });

  test("with query, operator suggestions are returned", () {
    final result =
        checkQuery(
              "some text role:admin AN",
              selectors: selectors,
              cursorOffset: 23,
            )
            .expectNoIssues()
            .expectQuery("some text AN")
            .expectExpression(
              (token) => token.isSelector(id: "role", value: "admin"),
            )
            .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();
    expect(operatorSuggestions, hasLength(1));
    expect(operatorSuggestions.first.operatorToken, "AND");
  });

  test(
    "with query after group and prefix operator, returns key suggestions",
    () {
      final result =
          checkQuery(
                "some thing #a AND NOT ",
                selectors: selectors,
                cursorOffset: 22,
              )
              .expectNoIssues()
              .expectQuery("some thing AND NOT")
              .expectExpression(
                (token) => token.isSelector(id: "tag", value: "a"),
              )
              .done();

      final suggestions = engine.suggest(result);

      final keySuggestions = suggestions
          .whereType<SelectorKeySuggestion>()
          .toList();
      expect(keySuggestions, hasLength(selectors.length));
      expect(
        keySuggestions.map((suggestion) => suggestion.selectorId),
        containsAll(selectors.map((s) => s.id)),
      );
    },
  );

  test("partial selector before selector returns key suggestions", () {
    final result =
        checkQuery("ti role:admin", selectors: selectors, cursorOffset: 2)
            .expectNoIssues()
            .expectQuery("ti")
            .expectExpression(
              (token) => token.isSelector(id: "role", value: "admin"),
            )
            .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test("partial selecteor after selector returns key suggestions", () {
    final result = checkQuery("#a ti", selectors: selectors, cursorOffset: 5)
        .expectNoIssues()
        .expectQuery("ti")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test("partial selector after operator returns key suggestions", () {
    final result =
        checkQuery("#a AND ti", selectors: selectors, cursorOffset: 9)
            .expectNoIssues()
            .expectQuery("AND ti")
            .expectExpression(
              (token) => token.isSelector(id: "tag", value: "a"),
            )
            .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test("partial selector after negation returns key suggestions", () {
    final result =
        checkQuery("#a NOT ti", selectors: selectors, cursorOffset: 9)
            .expectNoIssues()
            .expectQuery("NOT ti")
            .expectExpression(
              (token) => token.isSelector(id: "tag", value: "a"),
            )
            .done();

    final suggestions = engine.suggest(result);

    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();
    expect(keySuggestions, hasLength(1));
    expect(keySuggestions.first.selectorId, "title");
  });

  test(
    "cursor at start after query returns suggestions even with text after it",
    () {
      final result =
          checkQuery("#a  some", selectors: selectors, cursorOffset: 3)
              .expectNoIssues()
              .expectQuery("some")
              .expectExpression(
                (token) => token.isSelector(id: "tag", value: "a"),
              )
              .done();

      final suggestions = engine.suggest(result);

      final keySuggestions = suggestions
          .whereType<SelectorKeySuggestion>()
          .toList();
      expect(keySuggestions, hasLength(selectors.length));
      expect(
        keySuggestions.map((suggestion) => suggestion.selectorId),
        containsAll(selectors.map((s) => s.id)),
      );
    },
  );

  test("only prefix operator suggestions after group operator", () {
    final result = checkQuery("#a AND ", selectors: selectors, cursorOffset: 7)
        .expectNoIssues()
        .expectQuery("AND")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final suggestions = engine.suggest(result, maxItems: 1000);

    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();
    final tokens = operatorSuggestions.map((s) => s.operatorToken).toList();
    expect(tokens, containsAll(QueryOperator.prefixTokens));
    expect(tokens, isNot(contains(anyOf(QueryOperator.groupTokens))));
    expect(tokens, isNot(contains(anyOf(QueryOperator.postfixTokens))));
  });

  test("only prefix operator suggestions after prefix operator", () {
    final result = checkQuery("#a NOT ", selectors: selectors, cursorOffset: 7)
        .expectNoIssues()
        .expectQuery("NOT")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final suggestions = engine.suggest(result, maxItems: 1000);

    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();
    final tokens = operatorSuggestions.map((s) => s.operatorToken).toList();
    expect(tokens, containsAll(QueryOperator.prefixTokens));
    expect(tokens, isNot(contains(anyOf(QueryOperator.groupTokens))));
    expect(tokens, isNot(contains(anyOf(QueryOperator.postfixTokens))));
  });

  test(
    "only prefix operator suggestions after both group and prefix operator",
    () {
      final result =
          checkQuery("#a or not ", selectors: selectors, cursorOffset: 10)
              .expectNoIssues()
              .expectQuery("or not")
              .expectExpression(
                (token) => token.isSelector(id: "tag", value: "a"),
              )
              .done();

      final suggestions = engine.suggest(result, maxItems: 1000);

      final operatorSuggestions = suggestions
          .whereType<OperatorSuggestion>()
          .toList();
      final tokens = operatorSuggestions.map((s) => s.operatorToken).toList();
      expect(tokens, containsAll(QueryOperator.prefixTokens));
      expect(tokens, isNot(contains(anyOf(QueryOperator.groupTokens))));
      expect(tokens, isNot(contains(anyOf(QueryOperator.postfixTokens))));
    },
  );

  test("operator in middle of selectors returns suggestion", () {
    final result = checkQuery("#a AN #b", selectors: selectors, cursorOffset: 5)
        .expectNoIssues()
        .expectQuery("AN #b")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();
    expect(operatorSuggestions, hasLength(1));
    expect(operatorSuggestions.first.operatorToken, "AND");
  });

  test("operator before selector returns no suggestions", () {
    final result = checkQuery("AN #a", selectors: selectors, cursorOffset: 2)
        .expectNoIssues()
        .expectQuery("AN")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final suggestions = engine.suggest(result);
    expect(suggestions, isEmpty);
  });

  test("operator after selector returns suggestions", () {
    final result = checkQuery("#a O", selectors: selectors, cursorOffset: 4)
        .expectNoIssues()
        .expectQuery("O")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final engine = QuerySuggestionEngine(selectors);
    final suggestions = engine.suggest(result);

    final operatorSuggestions = suggestions
        .whereType<OperatorSuggestion>()
        .toList();
    expect(operatorSuggestions, isNotEmpty);
    expect(operatorSuggestions.first.operatorToken, "OR");
  });

  test(
    "with query, selector key suggestions are not returned when in middle of query",
    () {
      final result =
          checkQuery("some ro text", selectors: selectors, cursorOffset: 7)
              .expectNoIssues()
              .expectQuery("some ro text")
              .expectNoExpression()
              .done();

      final engine = QuerySuggestionEngine(selectors);
      final suggestions = engine.suggest(result);

      final keySuggestions = suggestions
          .whereType<SelectorKeySuggestion>()
          .toList();
      expect(keySuggestions, isEmpty);
    },
  );

  test(
    "with query, operator suggestions are not returned when in middle of query",
    () {
      final result =
          checkQuery(
                "some AN text role:admin",
                selectors: selectors,
                cursorOffset: 7,
              )
              .expectNoIssues()
              .expectQuery("some AN text")
              .expectExpression(
                (token) => token.isSelector(id: "role", value: "admin"),
              )
              .done();

      final engine = QuerySuggestionEngine(selectors);
      final suggestions = engine.suggest(result);

      final operatorSuggestions = suggestions
          .whereType<OperatorSuggestion>()
          .toList();
      expect(operatorSuggestions, isEmpty);
    },
  );

  test("selector with free value returns empty", () {
    final result = checkQuery("title:my", selectors: selectors, cursorOffset: 7)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "title", value: "my");
        })
        .done();
    final suggestions = engine.suggest(result);
    expect(suggestions, isEmpty);
  });

  test("value suggestion filters by prefix", () {
    final result = checkQuery("role:ad", selectors: selectors, cursorOffset: 7)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectExpression((token) => token.isSelector(id: "role", value: "ad"))
        .expectNoQuery()
        .done();
    final suggestions = engine.suggest(result);
    final valueSuggestions = suggestions.whereType<SelectorValueSuggestion>();
    expect(valueSuggestions.map((s) => s.value), contains("admin"));
    expect(valueSuggestions.map((s) => s.value), isNot(contains("author")));
  });

  test("selector key matching is case insensitive", () {
    final result = checkQuery(
      "TI",
      selectors: selectors,
      cursorOffset: 2,
    ).expectNoIssues().expectQuery("TI").expectNoExpression().done();

    final suggestions = engine.suggest(result);

    expect(
      suggestions.whereType<SelectorKeySuggestion>().any(
        (suggestion) => suggestion.selectorId == "title",
      ),
      isTrue,
    );
  });

  test("selector value matching is case insensitive", () {
    final result = checkQuery("role:AD", selectors: selectors, cursorOffset: 7)
        .expectIssues([QueryIssueCode.invalidSelectorValue])
        .expectExpression((token) => token.isSelector(id: "role", value: "AD"))
        .expectNoQuery()
        .done();

    final suggestions = engine.suggest(result);

    expect(
      suggestions.whereType<SelectorValueSuggestion>().any(
        (suggestion) => suggestion.value == "admin",
      ),
      isTrue,
    );
  });

  test("operator matching is case insensitive", () {
    final result = checkQuery("#a aN", selectors: selectors, cursorOffset: 5)
        .expectNoIssues()
        .expectQuery("aN")
        .expectExpression((token) => token.isSelector(id: "tag", value: "a"))
        .done();

    final suggestions = engine.suggest(result);

    expect(
      suggestions.whereType<OperatorSuggestion>().any(
        (suggestion) => suggestion.operatorToken == "AND",
      ),
      isTrue,
    );
  });

  test("empty query returns all key selectors", () {
    final result = checkQuery(
      "",
      selectors: selectors,
      cursorOffset: 0,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();

    final suggestions = engine.suggest(result);
    final keySuggestions = suggestions
        .whereType<SelectorKeySuggestion>()
        .toList();

    expect(keySuggestions, hasLength(selectors.length));
    expect(
      keySuggestions.map((suggestion) => suggestion.selectorId),
      containsAll(selectors.map((s) => s.id)),
    );
  });

  test(
    "returns no suggestions for single multiplicity selector which is already present",
    () {
      final result =
          checkQuery("id:1 id", selectors: selectors, cursorOffset: 7)
              .expectNoIssues()
              .expectExpression((token) {
                token.isSelector(id: "id", value: "1");
              })
              .expectQuery("id")
              .done();

      final suggestions = engine.suggest(result);
      final keySuggestions = suggestions
          .whereType<SelectorKeySuggestion>()
          .toList();
      final ids = keySuggestions.map((suggestion) => suggestion.selectorId);
      expect(ids, isNot(contains("id")));
    },
  );

  test("QuerySuggestionListX.key folds labels", () {
    final suggestions = [
      const SelectorKeySuggestion(
        label: "a",
        replaceRange: QueryRange(0, 0),
        selectorId: "x",
      ),
      const SelectorKeySuggestion(
        label: "b",
        replaceRange: QueryRange(0, 0),
        selectorId: "y",
      ),
      const SelectorKeySuggestion(
        label: "c",
        replaceRange: QueryRange(0, 0),
        selectorId: "z",
      ),
    ];
    expect(suggestions.key, "abc");
  });
}
