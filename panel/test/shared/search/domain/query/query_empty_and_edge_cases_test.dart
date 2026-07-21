import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/query_test_harness.dart";

void main() {
  final selectors = <QuerySelectorDefinition>[
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
  ];

  test("empty string returns empty result", () {
    final result = checkQuery(
      "",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();
    expect(result.expression, isNull);
    expect(result.selectors, isEmpty);
    expect(result.query, isEmpty);
    expect(result.queryBefore, isEmpty);
    expect(result.queryAfter, isEmpty);
    expect(result.raw, "");
    expect(result.issues, isEmpty);
    expect(result.cursorContext, isNull);
  });

  test("whitespace only returns empty result", () {
    final result = checkQuery(
      "   ",
      selectors: selectors,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();
    expect(result.expression, isNull);
    expect(result.selectors, isEmpty);
    expect(result.query, isEmpty);
    expect(result.queryBefore, isEmpty);
    expect(result.queryAfter, isEmpty);
    expect(result.raw, "");
    expect(result.issues, isEmpty);
    expect(result.cursorContext, isNull);
  });

  test("empty string with cursor returns unknown context", () {
    final result = checkQuery(
      "",
      selectors: selectors,
      cursorOffset: 0,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();
    expect(result.cursorContext, isA<UnknownCursorContext>());
    final ctx = result.cursorContext! as UnknownCursorContext;
    expect(ctx.side, QuerySide.before);
    expect(result.raw, "");
  });

  test("non-empty query with no selectors is treated as plain text", () {
    final result = checkQuery("title:test #tag", selectors: const [])
        .expectNoIssues()
        .expectQuery("title:test #tag")
        .expectNoExpression()
        .done();

    expect(result.selectors, isEmpty);
    expect(result.tokens, isEmpty);
    expect(result.queryBefore, "title:test #tag");
    expect(result.queryAfter, isEmpty);
    expect(result.raw, "title:test #tag");
  });

  test("lexer with no selectors tokenizes all input as plain text", () {
    final result = lexQuery("  title:test #tag  ", selectors: const []);

    expect(result.query, "title:test #tag");
    expect(result.queryBefore, "title:test #tag");
    expect(result.queryAfter, isEmpty);
    expect(result.expression, isNull);
    expect(result.raw, "  title:test #tag  ");
  });

  test("cursor beyond input length clamps", () {
    final result = checkQuery(
      "",
      selectors: selectors,
      cursorOffset: 100,
    ).expectNoIssues().expectNoQuery().expectNoExpression().done();
    expect(result.cursorContext, isA<UnknownCursorContext>());
    final ctx = result.cursorContext! as UnknownCursorContext;
    expect(ctx.cursorOffset, 0);
    expect(ctx.side, QuerySide.before);
    expect(result.raw, "");
  });

  test("cursor at end of input clamps", () {
    final result = checkQuery("#a", selectors: selectors, cursorOffset: 10)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();
    expect(result.cursorContext, isNotNull);
  });

  test("only symbol selector with no token", () {
    final result = checkQuery("#", selectors: selectors)
        .expectIssues([QueryIssueCode.missingSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "tag", value: null);
        })
        .done();
    expect(result.selectors, hasLength(1));
    final selector = result.selectors.single as QueryLexerKeyValueSelectorToken;
    expect(selector.value, isNull);
    expect(selector.valueRange, isNull);
    expect(result.issues, hasLength(1));
    expect(result.issues.first.code, QueryIssueCode.missingSelectorValue);
  });

  test("trailing operator is preserved as leftover query", () {
    final result = checkQuery("#a AND", selectors: selectors)
        .expectNoIssues()
        .expectQuery("AND")
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();
    expect(result.expression, isA<QueryLexerKeyValueSelectorToken>());
    expect(result.selectors, hasLength(1));
    expect(result.query.contains("AND"), isTrue);
    expect(result.queryBefore, isEmpty);
    expect(result.queryAfter, "AND");
  });

  test("extra closing parenthesis is preserved as leftover query", () {
    final result = checkQuery("#a)", selectors: selectors)
        .expectNoIssues()
        .expectQuery(")")
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();
    expect(result.expression, isA<QueryLexerKeyValueSelectorToken>());
    expect(result.selectors, hasLength(1));
    expect(result.query.contains(")"), isTrue);
    expect(result.queryBefore, isEmpty);
    expect(result.queryAfter, ")");
  });
}
