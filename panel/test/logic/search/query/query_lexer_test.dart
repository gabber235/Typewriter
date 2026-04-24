import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

import "query_test_harness.dart";

void main() {
  group("selector parsing", () {
    test("parses symbol selector", () {
      final result = checkLex("#hello").expectNoQuery().expectExpression((
        expression,
      ) {
        expression.isSelector(id: "tag", value: "hello");
      }).done();

      expect(result.queryBefore, isEmpty);
      expect(result.queryAfter, isEmpty);
      expect(result.raw, "#hello");
    });

    test("parses key value selector", () {
      final result = checkLex("title:test").expectNoQuery().expectExpression((
        expression,
      ) {
        expression.isSelector(id: "title", value: "test");
      }).done();

      expect(result.queryBefore, isEmpty);
      expect(result.queryAfter, isEmpty);
      expect(result.raw, "title:test");
    });

    test("reports missing selector value", () {
      checkLex("title:").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports unclosed quote", () {
      checkLex("title:\"unterminated").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "title", value: "unterminated").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports invalid enum value", () {
      checkLex("status:invalid").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "status", value: "invalid").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.invalidSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.warning,
        ]);
      }).done();
    });

    test("enforces selector key case sensitivity", () {
      checkLex("exact:ok").expectNoQuery().expectExpression((expression) {
        expression
            .range(const QueryRange(0, 8))
            .isSelector(id: "exact", value: "ok");
      }).done();

      final invalid = checkLex(
        "EXACT:ok",
      ).expectQuery("EXACT:ok").expectNoExpression().done();
      expect(invalid.queryBefore, "EXACT:ok");
      expect(invalid.queryAfter, isEmpty);
      expect(invalid.raw, "EXACT:ok");
    });

    test("parses selector key case insensitively by default", () {
      checkLex("TITLE:test").expectNoQuery().expectExpression((expression) {
        expression.isSelector(id: "title", value: "test");
      }).done();
    });

    test("parses single quoted selector value", () {
      checkLex("title:'hello'").expectNoQuery().expectExpression((expression) {
        expression.isSelector(id: "title", value: "hello");
      }).done();
    });

    test("parses single quoted selector value with spaces", () {
      checkLex("title:'hello world'").expectNoQuery().expectExpression((
        expression,
      ) {
        expression.isSelector(id: "title", value: "hello world");
      }).done();
    });

    test("parses quoted selector value with delimiter characters", () {
      checkLex("title:\"a|b&(c)\"").expectNoQuery().expectExpression((
        expression,
      ) {
        expression.isSelector(id: "title", value: "a|b&(c)");
      }).done();
    });

    test("parses valid quoted enum value", () {
      checkLex("status:\"open\"").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "status", value: "open").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues, isEmpty);
      }).done();
    });

    test("reports invalid quoted enum value", () {
      checkLex("status:\"invalid\"").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "status", value: "invalid").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.invalidSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.warning,
        ]);
      }).done();
    });

    test("reports unclosed single quote", () {
      checkLex("title:'unterminated").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "title", value: "unterminated").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports open double quote without value", () {
      checkLex("title:\"").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports open single quote without value", () {
      checkLex("title:'").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports missing selector value when key is followed by space", () {
      checkLex("title: ").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("parses operator keyword as plain selector value", () {
      checkLex("title:AND").expectNoQuery().expectExpression((expression) {
        expression.isSelector(id: "title", value: "AND");
      }).done();
    });

    test("parses quoted operator keywords as selector value", () {
      checkLex("title:\"AND OR NOT\"").expectNoQuery().expectExpression((
        expression,
      ) {
        expression.isSelector(id: "title", value: "AND OR NOT");
      }).done();
    });

    test("reports missing value for empty quoted enum", () {
      checkLex("status:\"\"").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "status", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("reports stacked issues for invalid unclosed quoted enum", () {
      checkLex("status:\"invalid").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "status", value: "invalid").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
          QueryIssueCode.invalidSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
          QuerySeverity.warning,
        ]);
      }).done();
    });
  });

  group("negation", () {
    test("parses word negation", () {
      checkLex("NOT #tag").expectNoQuery().expectExpression((expression) {
        final negation = expression.range(const QueryRange(0, 8)).isNot();
        negation.inner().isSelector(id: "tag", value: "tag");
      }).done();
    });

    test("parses symbolic negation", () {
      checkLex("!title:test").expectNoQuery().expectExpression((expression) {
        final negation = expression.range(const QueryRange(0, 11)).isNot();
        negation.inner().isSelector(id: "title", value: "test");
      }).done();
    });

    test("parses nested negation", () {
      checkLex("NOT NOT #a").expectNoQuery().expectExpression((expression) {
        final outer = expression.isNot();
        final inner = outer.inner().isNot();
        inner.inner().isSelector(id: "tag", value: "a");
      }).done();
    });

    test("accepts word negation without whitespace", () {
      checkLex("NOT#tag").expectNoQuery().expectExpression((expression) {
        final negation = expression.isNot();
        negation.inner().isSelector(id: "tag", value: "tag");
      }).done();
    });

    test("parses lowercase word negation", () {
      checkLex("not #tag").expectNoQuery().expectExpression((expression) {
        final negation = expression.isNot();
        negation.inner().isSelector(id: "tag", value: "tag");
      }).done();
    });

    test("parses symbolic double negation", () {
      checkLex("!!#a").expectNoQuery().expectExpression((expression) {
        final outer = expression.isNot();
        final inner = outer.inner().isNot();
        inner.inner().isSelector(id: "tag", value: "a");
      }).done();
    });

    test("parses negation of grouped expression", () {
      checkLex("!(#a OR #b)").expectNoQuery().expectExpression((expression) {
        final negation = expression.isNot();
        final or = negation.inner().isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("parses word negation of grouped expression without whitespace", () {
      checkLex("NOT(#a OR #b)").expectNoQuery().expectExpression((expression) {
        final negation = expression.isNot();
        final or = negation.inner().isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });
  });

  group("operator precedence and grouping", () {
    test("AND binds tighter than OR", () {
      checkLex("#a OR #b AND #c").expectNoQuery().expectExpression((
        expression,
      ) {
        final or = expression.isOr();
        or.left().isSelector(id: "tag", value: "a");
        final and = or.right().isAnd();
        and.left().isSelector(id: "tag", value: "b");
        and.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("parentheses override precedence", () {
      checkLex("(#a OR #b) AND #c").expectNoQuery().expectExpression((
        expression,
      ) {
        final and = expression.isAnd();
        final or = and.left().isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
        and.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("same precedence operators are left associative", () {
      checkLex("#a AND #b AND #c").expectNoQuery().expectExpression((
        expression,
      ) {
        final outer = expression.isAnd();
        final inner = outer.left().isAnd();
        inner.left().isSelector(id: "tag", value: "a");
        inner.right().isSelector(id: "tag", value: "b");
        outer.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("supports symbolic operators without whitespace", () {
      checkLex("#a&&#b||#c").expectNoQuery().expectExpression((expression) {
        final or = expression.isOr();
        final and = or.left().isAnd();
        and.left().isSelector(id: "tag", value: "a");
        and.right().isSelector(id: "tag", value: "b");
        or.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("supports symbolic OR without whitespace", () {
      checkLex("#a||#b").expectNoQuery().expectExpression((expression) {
        final or = expression.isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("parses lowercase and mixed case operators", () {
      checkLex("#a AnD #b oR #c").expectNoQuery().expectExpression((
        expression,
      ) {
        final or = expression.isOr();
        final and = or.left().isAnd();
        and.left().isSelector(id: "tag", value: "a");
        and.right().isSelector(id: "tag", value: "b");
        or.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("OR operators are left associative", () {
      checkLex("#a OR #b OR #c").expectNoQuery().expectExpression((expression) {
        final outer = expression.isOr();
        final inner = outer.left().isOr();
        inner.left().isSelector(id: "tag", value: "a");
        inner.right().isSelector(id: "tag", value: "b");
        outer.right().isSelector(id: "tag", value: "c");
      }).done();
    });

    test("NOT binds tighter than AND and OR", () {
      checkLex("not #a || #b and #c").expectNoQuery().expectExpression((
        expression,
      ) {
        final or = expression.isOr();
        final not = or.left().isNot();
        not.inner().isSelector(id: "tag", value: "a");
        final and = or.right().isAnd();
        and.left().isSelector(id: "tag", value: "b");
        and.right().isSelector(id: "tag", value: "c");
      }).done();
    });
  });

  group("leftover query", () {
    test("fails fast when no expression is present", () {
      checkLex(
        "hello world",
      ).expectQuery("hello world").expectNoExpression().done();
    });

    test("keeps prefix and suffix outside parsed expression", () {
      checkLex(
        "prefix #a suffix",
      ).expectQuery("prefix suffix").expectExpression((expression) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("keeps suffix text outside parsed expression", () {
      checkLex("#a trailing").expectQuery("trailing").expectExpression((
        expression,
      ) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("keeps prefix text outside parsed expression", () {
      checkLex("prefix #a").expectQuery("prefix").expectExpression((
        expression,
      ) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("keeps multiple free text chunks around parsed expression", () {
      checkLex(
        "pre one #a post two",
      ).expectQuery("pre one post two").expectExpression((expression) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("keeps free text before grouped expression", () {
      checkLex("before (#a OR #b)").expectQuery("before").expectExpression((
        expression,
      ) {
        final or = expression.isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("keeps free text after grouped expression", () {
      checkLex("(#a OR #b) after").expectQuery("after").expectExpression((
        expression,
      ) {
        final or = expression.isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("keeps only free text when expression is absent", () {
      checkLex(
        "text only",
      ).expectQuery("text only").expectNoExpression().done();
    });

    test("leaves trailing unmatched parenthesis as leftover text", () {
      checkLex("#a)").expectQuery(")").expectExpression((expression) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("leaves trailing operator text as leftover text", () {
      checkLex("#a AND").expectQuery("AND").expectExpression((expression) {
        expression.isSelector(id: "tag", value: "a");
      }).done();
    });

    test("leaves opening parenthesis as leftover when group is unclosed", () {
      checkLex("(#a OR #b").expectQuery("(").expectExpression((expression) {
        final or = expression.isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("throws when only empty parentheses are present", () {
      checkLex("()").expectQuery("()").expectNoExpression().done();
    });
  });

  group("range integrity", () {
    test("tracks key and value ranges for key value selector", () {
      checkLex("title:test").expectNoQuery().expectExpression((expression) {
        final selector =
            expression
                    .range(const QueryRange(0, 10))
                    .isSelector(id: "title", value: "test")
                    .token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.keyRange, const QueryRange(0, 6));
        expect(selector.valueRange, const QueryRange(6, 10));
      }).done();
    });

    test(
      "operator range spans full grouped expression without parentheses",
      () {
        checkLex("(#a OR #b)").expectNoQuery().expectExpression((expression) {
          final or = expression.range(const QueryRange(1, 9)).isOr();
          or.left().isSelector(id: "tag", value: "a");
          or.right().isSelector(id: "tag", value: "b");
        }).done();
      },
    );

    test("operator range includes both operands and operator", () {
      checkLex("#a && #b").expectNoQuery().expectExpression((expression) {
        final and = expression.range(const QueryRange(0, 8)).isAnd();
        and.left().isSelector(id: "tag", value: "a");
        and.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("negation range includes operator and operand", () {
      checkLex("! #a").expectNoQuery().expectExpression((expression) {
        final negation = expression.range(const QueryRange(0, 4)).isNot();
        negation.inner().isSelector(id: "tag", value: "a");
      }).done();
    });

    test("OR operator range includes both operands and operator", () {
      checkLex("#a OR #b").expectNoQuery().expectExpression((expression) {
        final or = expression.range(const QueryRange(0, 8)).isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("symbolic OR range includes both operands and operator", () {
      checkLex("#a||#b").expectNoQuery().expectExpression((expression) {
        final or = expression.range(const QueryRange(0, 6)).isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("grouped negation range includes operator and operand", () {
      checkLex("!(#a OR #b)").expectNoQuery().expectExpression((expression) {
        final negation = expression.range(const QueryRange(0, 10)).isNot();
        final or = negation.inner().isOr();
        or.left().isSelector(id: "tag", value: "a");
        or.right().isSelector(id: "tag", value: "b");
      }).done();
    });

    test("nested symbolic negation range spans both prefixes", () {
      checkLex("!!#a").expectNoQuery().expectExpression((expression) {
        final outer = expression.range(const QueryRange(0, 4)).isNot();
        final inner = outer.inner().range(const QueryRange(1, 4)).isNot();
        inner.inner().isSelector(id: "tag", value: "a");
      }).done();
    });

    test("quoted value range includes quote characters", () {
      checkLex("title:\"hello\"").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "title", value: "hello").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.valueRange, const QueryRange(6, 13));
      }).done();
    });

    test("single quoted value range includes quote characters", () {
      checkLex("title:'hello'").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: "hello").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.valueRange, const QueryRange(6, 13));
      }).done();
    });
  });

  group("issue semantics", () {
    test("missing selector value has error severity", () {
      checkLex("title:").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "title", value: null).token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.missingSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("unclosed quote has error severity", () {
      checkLex("title:\"unterminated").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "title", value: "unterminated").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
        ]);
      }).done();
    });

    test("invalid selector value has warning severity", () {
      checkLex("status:invalid").expectNoQuery().expectExpression((expression) {
        final selector =
            expression.isSelector(id: "status", value: "invalid").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.invalidSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.warning,
        ]);
      }).done();
    });

    test("stacked issue order is deterministic", () {
      checkLex("status:\"invalid").expectNoQuery().expectExpression((
        expression,
      ) {
        final selector =
            expression.isSelector(id: "status", value: "invalid").token()
                as QueryLexerKeyValueSelectorToken;
        expect(selector.issues.map((issue) => issue.code).toList(), [
          QueryIssueCode.unclosedQuote,
          QueryIssueCode.invalidSelectorValue,
        ]);
        expect(selector.issues.map((issue) => issue.severity).toList(), [
          QuerySeverity.error,
          QuerySeverity.warning,
        ]);
      }).done();
    });
  });
}
