import "package:petitparser/debug.dart";
import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/shared/search/domain/query/query.dart";

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

sealed class QueryLexerToken {
  const QueryLexerToken({
    required this.raw,
    required this.range,
    this.issues = const <QueryParseIssue>[],
  });
  final String raw;
  final QueryRange range;
  final List<QueryParseIssue> issues;
}

class QueryLexerSelectorToken extends QueryLexerToken {
  const QueryLexerSelectorToken({
    required this.selectorId,
    required super.raw,
    required super.range,
    super.issues,
  });

  final String selectorId;

  @override
  String toString() {
    return "QueryLexerSelectorToken(selectorId: '$selectorId', raw: '$raw', range: ${this.range}, issues: $issues)";
  }
}

class QueryLexerKeyValueSelectorToken extends QueryLexerSelectorToken {
  const QueryLexerKeyValueSelectorToken({
    required super.selectorId,
    required this.keyRange,
    required super.raw,
    required super.range,
    this.value,
    this.valueRange,
    super.issues,
  }) : assert(
         value != null || issues.length > 0,
         "When no value is provided, an issue must be present",
       );

  final QueryRange keyRange;
  final String? value;
  final QueryRange? valueRange;

  @override
  String toString() {
    return "QueryLexerKeyValueSelectorToken(selectorId: '$selectorId', keyRange: $keyRange, value: '$value', valueRange: $valueRange, raw: '$raw', range: ${this.range}, issues: $issues)";
  }
}

class QueryLexerOperatorToken extends QueryLexerToken {
  const QueryLexerOperatorToken({
    required this.type,
    required super.raw,
    required super.range,
    required this.left,
    required this.right,
    required this.operatorRange,
    super.issues,
  });

  final QueryLexerOperatorType type;
  final QueryLexerToken left;
  final QueryLexerToken right;

  final QueryRange? operatorRange;

  @override
  String toString() {
    return "QueryLexerOperatorToken(type: $type, left: $left, right: $right, operatorRange: $operatorRange, raw: '$raw', range: ${this.range}, issues: $issues)";
  }
}

class QueryLexerNegationToken extends QueryLexerToken {
  const QueryLexerNegationToken({
    required this.token,
    required super.raw,
    required super.range,
    required this.operatorRange,
    super.issues,
  });

  final QueryLexerToken token;
  final QueryRange operatorRange;

  @override
  String toString() {
    return "QueryLexerNegationToken(token: $token, operatorRange: $operatorRange, raw: '$raw', range: ${this.range}, issues: $issues)";
  }
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
      case QueryLexerSelectorToken():
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
