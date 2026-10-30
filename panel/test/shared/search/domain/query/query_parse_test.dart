import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final key in ["#", "tag:"]) {
    group("a selector with key '$key'", () {
      final selectors = [KeyValueSelectorDefinition(id: "tag", key: key)];
      final k = key.length;

      test("reads an unquoted value", () {
        final result = checkQuery("${key}hello", selectors: selectors)
            .expectNoIssues()
            .expectNoQuery()
            .expectExpression((expression) {
              expression.isSelector(id: "tag", value: "hello");
            })
            .done();
        expect(
          (result.selectors.single as QueryLexerKeyValueSelectorToken)
              .valueRange,
          QueryRange(k, k + 5),
        );
      });

      for (final quote in quotes) {
        test("reads a $quote quoted value including its quotes", () {
          final result =
              checkQuery(
                "$key${quote}hello there$quote",
                selectors: selectors,
              ).expectNoIssues().expectNoQuery().expectExpression((expression) {
                expression.isSelector(id: "tag", value: "hello there");
              }).done();
          expect(
            (result.selectors.single as QueryLexerKeyValueSelectorToken)
                .valueRange,
            QueryRange(k, k + 13),
          );
        });

        test("reports an unclosed $quote quote and keeps its value", () {
          final result =
              checkQuery("$key${quote}hello there", selectors: selectors)
                  .expectIssuesExactly([
                    (
                      QueryIssueCode.unclosedQuote,
                      QuerySeverity.error,
                      QueryRange(k, k + 12),
                    ),
                  ])
                  .expectNoQuery()
                  .expectExpression((expression) {
                    expression.isSelector(id: "tag", value: "hello there");
                  })
                  .done();
          expect(
            (result.selectors.single as QueryLexerKeyValueSelectorToken)
                .valueRange,
            QueryRange(k, k + 12),
          );
        });

        test("reports a lone $quote quote as unclosed and missing", () {
          final result = checkQuery("$key$quote", selectors: selectors)
              .expectIssuesExactly([
                (
                  QueryIssueCode.unclosedQuote,
                  QuerySeverity.error,
                  QueryRange(k, k + 1),
                ),
                (
                  QueryIssueCode.missingSelectorValue,
                  QuerySeverity.error,
                  QueryRange(0, k + 1),
                ),
              ])
              .expectNoQuery()
              .expectExpression((expression) {
                expression.isSelector(id: "tag", value: null);
              })
              .done();
          expect(
            (result.selectors.single as QueryLexerKeyValueSelectorToken)
                .valueRange,
            QueryRange(k, k + 1),
          );
        });
      }

      for (final input in [key, "$key hello"]) {
        test("reports a missing value for '$input' on the key", () {
          final result = checkQuery(input, selectors: selectors)
              .expectIssuesExactly([
                (
                  QueryIssueCode.missingSelectorValue,
                  QuerySeverity.error,
                  QueryRange(0, k),
                ),
              ])
              .expectQuery(input == key ? "" : "hello")
              .expectExpression((expression) {
                expression.isSelector(id: "tag", value: null);
              })
              .done();
          expect(
            (result.selectors.single as QueryLexerKeyValueSelectorToken)
                .valueRange,
            isNull,
          );
        });
      }

      test("ends the value at whitespace and keeps the rest as text", () {
        checkQuery(
          "${key}hello after",
          selectors: selectors,
        ).expectNoIssues().expectQuery("after").expectExpression((expression) {
          expression.isSelector(id: "tag", value: "hello");
        }).done();
      });
    });
  }

  group("selector values", () {
    final values = {
      "#hello": (id: "tag", value: "hello"),
      "title:test": (id: "title", value: "test"),
      "TITLE:test": (id: "title", value: "test"),
      "exact:ok": (id: "exact", value: "ok"),
      "title:'hello world'": (id: "title", value: "hello world"),
      "title:\"a|b&(c)\"": (id: "title", value: "a|b&(c)"),
      "status:\"open\"": (id: "status", value: "open"),
      "title:AND": (id: "title", value: "AND"),
      "title:\"AND OR NOT\"": (id: "title", value: "AND OR NOT"),
    };
    for (final MapEntry(key: input, value: (:id, :value)) in values.entries) {
      test("'$input' selects $id with value '$value'", () {
        checkQuery(input)
            .expectNoIssues()
            .expectNoQuery()
            .expectExpression((expression) {
              expression
                  .range(QueryRange(0, input.length))
                  .isSelector(id: id, value: value);
            })
            .done();
      });
    }

    test("a case sensitive key in the wrong case stays free text", () {
      final result = checkQuery("EXACT:ok")
          .expectNoIssues()
          .expectQuery("EXACT:ok")
          .expectNoExpression()
          .done();
      expect(result.queryBefore, "EXACT:ok");
      expect(result.queryAfter, isEmpty);
    });
  });

  group("selector issues", () {
    const error = QuerySeverity.error;
    const warning = QuerySeverity.warning;
    const missing = QueryIssueCode.missingSelectorValue;
    const unclosed = QueryIssueCode.unclosedQuote;
    const invalid = QueryIssueCode.invalidSelectorValue;
    final cases = {
      "title:": (
        value: null,
        issues: [(missing, error, const QueryRange(0, 6))],
      ),
      "title: ": (
        value: null,
        issues: [(missing, error, const QueryRange(0, 6))],
      ),
      "title:\"unterminated": (
        value: "unterminated",
        issues: [(unclosed, error, const QueryRange(6, 19))],
      ),
      "title:'unterminated": (
        value: "unterminated",
        issues: [(unclosed, error, const QueryRange(6, 19))],
      ),
      "status:invalid": (
        value: "invalid",
        issues: [(invalid, warning, const QueryRange(7, 14))],
      ),
      "status:\"invalid\"": (
        value: "invalid",
        issues: [(invalid, warning, const QueryRange(7, 16))],
      ),
      "status:\"\"": (
        value: null,
        issues: [(missing, error, const QueryRange(0, 9))],
      ),
      "status:\"invalid": (
        value: "invalid",
        issues: [
          (unclosed, error, const QueryRange(7, 15)),
          (invalid, warning, const QueryRange(7, 15)),
        ],
      ),
    };
    for (final MapEntry(key: input, value: (:value, :issues))
        in cases.entries) {
      test("'$input' reports ${issues.map((issue) => issue.$1.name)}", () {
        checkQuery(input)
            .expectIssuesExactly(issues)
            .expectNoQuery()
            .expectExpression((expression) {
              expression.isSelector(
                id: input.startsWith("title") ? "title" : "status",
                value: value,
              );
            })
            .done();
      });
    }
  });

  group("negation", () {
    test("word negation spans the operator and its operand", () {
      checkQuery("NOT #tag")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final negation = expression.range(const QueryRange(0, 8)).isNot();
            negation.inner().isSelector(id: "tag", value: "tag");
          })
          .done();
    });

    test("symbolic negation spans the operator and its operand", () {
      checkQuery("!title:test")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final negation = expression.range(const QueryRange(0, 11)).isNot();
            negation.inner().isSelector(id: "title", value: "test");
          })
          .done();
    });

    for (final input in ["NOT#tag", "not #tag"]) {
      test("'$input' negates the selector", () {
        checkQuery(input)
            .expectNoIssues()
            .expectNoQuery()
            .expectExpression((expression) {
              expression.isNot().inner().isSelector(id: "tag", value: "tag");
            })
            .done();
      });
    }

    test("repeated symbolic negation nests", () {
      checkQuery("!!#a")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final outer = expression.range(const QueryRange(0, 4)).isNot();
            final inner = outer.inner().range(const QueryRange(1, 4)).isNot();
            inner.inner().isSelector(id: "tag", value: "a");
          })
          .done();
    });

    for (final input in ["!(#a OR #b)", "NOT(#a OR #b)"]) {
      test("'$input' negates the whole group", () {
        checkQuery(input)
            .expectNoIssues()
            .expectNoQuery()
            .expectExpression((expression) {
              final negation = expression
                  .range(QueryRange(0, input.length - 1))
                  .isNot();
              final or = negation.inner().isOr();
              or.left().isSelector(id: "tag", value: "a");
              or.right().isSelector(id: "tag", value: "b");
            })
            .done();
      });
    }
  });

  group("binary operators", () {
    test("AND is left associative", () {
      checkQuery("#a AND #b AND #c")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final outer = expression.isAnd();
            final inner = outer.left().isAnd();
            inner.left().isSelector(id: "tag", value: "a");
            inner.right().isSelector(id: "tag", value: "b");
            outer.right().isSelector(id: "tag", value: "c");
          })
          .done();
    });

    test("OR is left associative", () {
      checkQuery("#a OR #b OR #c")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final outer = expression.isOr();
            final inner = outer.left().isOr();
            inner.left().isSelector(id: "tag", value: "a");
            inner.right().isSelector(id: "tag", value: "b");
            outer.right().isSelector(id: "tag", value: "c");
          })
          .done();
    });

    test("symbolic operators need no whitespace", () {
      checkQuery("#a&&#b||#c")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final or = expression.range(const QueryRange(0, 10)).isOr();
            final and = or.left().range(const QueryRange(0, 6)).isAnd();
            and.left().isSelector(id: "tag", value: "a");
            and.right().isSelector(id: "tag", value: "b");
            or.right().isSelector(id: "tag", value: "c");
          })
          .done();
    });

    test("a group keeps the range of its content without parentheses", () {
      checkQuery("(#a OR #b)")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final or = expression.range(const QueryRange(1, 9)).isOr();
            or.left().isSelector(id: "tag", value: "a");
            or.right().isSelector(id: "tag", value: "b");
          })
          .done();
    });

    test("a symbolic AND spans both operands", () {
      checkQuery("#a && #b")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final and = expression.range(const QueryRange(0, 8)).isAnd();
            and.left().isSelector(id: "tag", value: "a");
            and.right().isSelector(id: "tag", value: "b");
          })
          .done();
    });

    test("negation with a space spans the operator and its operand", () {
      checkQuery("! #a")
          .expectNoIssues()
          .expectNoQuery()
          .expectExpression((expression) {
            final negation = expression.range(const QueryRange(0, 4)).isNot();
            negation.inner().isSelector(id: "tag", value: "a");
          })
          .done();
    });
  });

  group("free text around the expression", () {
    final leftovers = {
      "prefix #a suffix": (before: "prefix", after: "suffix"),
      "#a trailing": (before: "", after: "trailing"),
      "prefix #a": (before: "prefix", after: ""),
      "pre one #a post two": (before: "pre one", after: "post two"),
      "#a)": (before: "", after: ")"),
      "#a AND": (before: "", after: "AND"),
    };
    for (final MapEntry(key: input, value: (:before, :after))
        in leftovers.entries) {
      test("'$input' keeps '$before' before and '$after' after", () {
        final result = checkQuery(input)
            .expectNoIssues()
            .expectQuery([before, after].join(" ").trim())
            .expectExpression((expression) {
              expression.isSelector(id: "tag", value: "a");
            })
            .done();
        expect(result.queryBefore, before);
        expect(result.queryAfter, after);
      });
    }

    final groups = {
      "before (#a OR #b)": "before",
      "(#a OR #b) after": "after",
      "(#a OR #b": "(",
    };
    for (final MapEntry(key: input, value: text) in groups.entries) {
      test("'$input' keeps '$text' outside the group", () {
        checkQuery(input)
            .expectNoIssues()
            .expectQuery(text)
            .expectExpression((expression) {
              final or = expression.isOr();
              or.left().isSelector(id: "tag", value: "a");
              or.right().isSelector(id: "tag", value: "b");
            })
            .done();
      });
    }

    test("text without selectors stays free text", () {
      checkQuery("text only")
          .expectNoIssues()
          .expectQuery("text only")
          .expectNoExpression()
          .done();
    });

    test("empty parentheses stay free text", () {
      checkQuery("()")
          .expectNoIssues()
          .expectQuery("()")
          .expectNoExpression()
          .done();
    });
  });

  test("a selector key and value keep their own ranges", () {
    final result = checkQuery("title:test")
        .expectNoIssues()
        .expectNoQuery()
        .expectExpression((expression) {
          expression
              .range(const QueryRange(0, 10))
              .isSelector(id: "title", value: "test");
        })
        .done();
    final selector = result.selectors.single as QueryLexerKeyValueSelectorToken;
    expect(selector.keyRange, const QueryRange(0, 6));
    expect(selector.valueRange, const QueryRange(6, 10));
  });

  for (final quote in quotes) {
    test(
      "a cursor in a $quote quoted value edits the value with its quotes",
      () {
        final result = checkQuery("title:${quote}hello$quote", cursorOffset: 9)
            .expectNoIssues()
            .expectNoQuery()
            .expectExpression((expression) {
              expression.isSelector(id: "title", value: "hello");
            })
            .done();
        expect(
          result.cursorContext,
          isA<SelectorValueCursorContext>()
              .having((context) => context.selectorId, "selectorId", "title")
              .having(
                (context) => context.activeRange,
                "activeRange",
                const QueryRange(6, 13),
              )
              .having(
                (context) => context.valueRange,
                "valueRange",
                const QueryRange(6, 13),
              ),
        );
      },
    );
  }
}
