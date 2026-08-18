import "package:freezed_annotation/freezed_annotation.dart";
import "package:petitparser/debug.dart";
import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "query_lexer.freezed.dart";

final _andOperatorParser = [
  string("AND", ignoreCase: true),
  string("&&"),
].toChoiceParser();

final _orOperatorParser = [
  string("OR", ignoreCase: true),
  string("||"),
].toChoiceParser();

final _notOperatorParser = [
  string("NOT", ignoreCase: true),
  string("!"),
].toChoiceParser();

class QueryLexer {
  QueryLexer(List<QuerySelectorDefinition> selectors) {
    if (selectors.isEmpty) {
      parser = any().star().flatten().map((input) {
        final query = input.trim();
        return QueryLexerResult(
          query: query,
          queryBefore: query,
          queryAfter: "",
          raw: "",
          expression: null,
        );
      }).end();
      return;
    }

    final builder = ExpressionBuilder<QueryLexerToken>();

    for (final selector in selectors) {
      builder.primitive(selector.parser());
    }

    builder.group().wrapper(
      char("(").trim(),
      char(")").trim(),
      (left, value, right) => value,
    );

    builder.group().prefix(_notOperatorParser.token().trim(), (
      operator,
      value,
    ) {
      final range = operator.range.expandTo(value.range);
      final raw = operator.value + value.raw;
      return QueryLexerNegationToken(
        token: value,
        raw: raw,
        range: range,
        operatorRange: operator.range,
      );
    });

    builder.group().left(_andOperatorParser.token().trim(), (
      left,
      operator,
      right,
    ) {
      final range = left.range.expandTo(right.range);
      final raw = "${left.raw} ${operator.value} ${right.raw}";
      return QueryLexerOperatorToken(
        type: QueryLexerOperatorType.and,
        left: left,
        right: right,
        raw: raw,
        range: range,
        operatorRange: operator.range,
      );
    });

    builder.group().left(_orOperatorParser.token().trim(), (
      left,
      operator,
      right,
    ) {
      final range = left.range.expandTo(right.range);
      final raw = "${left.raw} ${operator.value} ${right.raw}";
      return QueryLexerOperatorToken(
        type: QueryLexerOperatorType.or,
        left: left,
        right: right,
        raw: raw,
        range: range,
        operatorRange: operator.range,
      );
    });

    builder.group().postfix(builder.build().trim(), (first, second) {
      final range = first.range.expandTo(second.range);
      final raw = "${first.raw} ${second.raw}";
      return QueryLexerOperatorToken(
        type: QueryLexerOperatorType.and,
        left: first,
        right: second,
        raw: raw,
        range: range,
        operatorRange: null,
      );
    });

    final expression = builder.build();

    parser =
        (any().starLazy(expression).flatten().optional() &
                expression.optional() &
                any().star().flatten())
            .map((list) {
              final [String? left, QueryLexerToken? expression, String? right] =
                  list;
              final queryBefore = left?.trim() ?? "";
              final queryAfter = right?.trim() ?? "";
              final query = [queryBefore, queryAfter].join(" ").trim();
              return QueryLexerResult(
                query: query,
                queryBefore: expression == null ? query : queryBefore,
                queryAfter: expression == null ? "" : queryAfter,
                raw: "",
                expression: expression,
              );
            })
            .end();
  }

  late final Parser<QueryLexerResult> parser;

  QueryLexerResult tokenize(String input) {
    final result = parser.parse(input);
    assert(() {
      if (result is Success) {
        return true;
      }

      trace(parser).parse(input);

      return false;
    }(), "Could not parse input: '$input': ${result.message}");
    final value = result.value;
    return QueryLexerResult(
      query: value.query,
      queryBefore: value.queryBefore,
      queryAfter: value.queryAfter,
      raw: input,
      expression: value.expression,
    );
  }
}

class QueryLexerResult {
  const QueryLexerResult({
    required this.query,
    required this.queryBefore,
    required this.queryAfter,
    required this.raw,
    this.expression,
  });

  /// Non selector text remainder, normalized from queryBefore and queryAfter.
  final String query;

  /// Non selector text that appears before the parsed expression.
  final String queryBefore;

  /// Non selector text that appears after the parsed expression.
  final String queryAfter;

  /// Original raw input string before parsing.
  final String raw;

  final QueryLexerToken? expression;
}

abstract interface class QueryLexerSelectorToken {
  String get selectorId;
  String get raw;
  QueryRange get range;
  List<QueryParseIssue> get issues;
}

@freezed
sealed class QueryLexerToken with _$QueryLexerToken {
  @Implements<QueryLexerSelectorToken>()
  @Assert(
    "value != null || issues.length > 0",
    "When no value is provided, an issue must be present",
  )
  const factory QueryLexerToken.keyValueSelector({
    required String selectorId,
    required QueryRange keyRange,
    required String raw,
    required QueryRange range,
    String? value,
    QueryRange? valueRange,
    @Default(<QueryParseIssue>[]) List<QueryParseIssue> issues,
  }) = QueryLexerKeyValueSelectorToken;

  const factory QueryLexerToken.operator({
    required QueryLexerOperatorType type,
    required String raw,
    required QueryRange range,
    required QueryLexerToken left,
    required QueryLexerToken right,
    required QueryRange? operatorRange,
    @Default(<QueryParseIssue>[]) List<QueryParseIssue> issues,
  }) = QueryLexerOperatorToken;

  const factory QueryLexerToken.negation({
    required QueryLexerToken token,
    required String raw,
    required QueryRange range,
    required QueryRange operatorRange,
    @Default(<QueryParseIssue>[]) List<QueryParseIssue> issues,
  }) = QueryLexerNegationToken;
}

enum QueryLexerOperatorType { and, or }

extension QueryLexerTokenX on QueryLexerToken {
  List<QueryLexerToken> flatten() {
    final result = <QueryLexerToken>[];
    _flatten(this, result);
    return result;
  }

  void _flatten(QueryLexerToken token, List<QueryLexerToken> result) {
    switch (token) {
      case QueryLexerKeyValueSelectorToken():
        result.add(token);
      case QueryLexerOperatorToken():
        _flatten(token.left, result);
        result.add(token);
        _flatten(token.right, result);
      case QueryLexerNegationToken():
        result.add(token);
        _flatten(token.token, result);
    }
  }
}
