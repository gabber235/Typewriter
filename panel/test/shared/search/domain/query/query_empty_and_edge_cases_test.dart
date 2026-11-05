import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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
    final result = checkQuery("  title:test #tag  ", selectors: const [])
        .expectNoIssues()
        .expectQuery("title:test #tag")
        .expectNoExpression()
        .done();

    expect(result.selectors, isEmpty);
    expect(result.tokens, isEmpty);
    expect(result.query, "title:test #tag");
    expect(result.queryBefore, "title:test #tag");
    expect(result.queryAfter, isEmpty);
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

  test("a cursor past the end clamps into the last selector value", () {
    final result = checkQuery("#a", selectors: selectors, cursorOffset: 10)
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();
    expect(
      result.cursorContext,
      const SelectorValueCursorContext(
        cursorOffset: 2,
        activeRange: QueryRange(1, 2),
        selectorId: "tag",
        partialValue: "a",
        keyRange: QueryRange(0, 1),
        valueRange: QueryRange(1, 2),
      ),
    );
  });

  test("a bare selector key reports a missing value", () {
    final result = checkQuery("#", selectors: selectors)
        .expectIssues([QueryIssueCode.missingSelectorValue])
        .expectNoQuery()
        .expectExpression((token) {
          token.isSelector(id: "tag", value: null);
        })
        .done();
    expect(result.issues.map((issue) => (issue.code, issue.range)), [
      (QueryIssueCode.missingSelectorValue, const QueryRange(0, 1)),
    ]);
  });

  // Found by query_properties_test: sources match the free text as one
  // phrase, so repeated spaces must not change it.
  test("free text collapses repeated whitespace", () {
    final result = checkQuery("hello   world #a  again", selectors: selectors)
        .expectNoIssues()
        .expectQuery("hello world again")
        .expectExpression((token) {
          token.isSelector(id: "tag", value: "a");
        })
        .done();
    expect(result.query, "hello world again");
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
