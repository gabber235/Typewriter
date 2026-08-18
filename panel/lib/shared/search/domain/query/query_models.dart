import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "query_models.freezed.dart";

enum QueryOperatorType { prefix, group, postfix }

enum QueryOperator {
  and(["AND", "&&"], type: .group),
  or(["OR", "||"], type: .group),
  not(["NOT", "!"], type: .prefix);

  const QueryOperator(this.tokens, {required this.type});
  final List<String> tokens;
  final QueryOperatorType type;

  static List<String> allTokens([List<QueryOperatorType>? types]) => values
      .where((type) => types == null || types.contains(type.type))
      .expand((type) => type.tokens)
      .toList(growable: false);

  static List<String> tokensForType(QueryOperatorType type) {
    return values
        .where((t) => t.type == type)
        .expand((type) => type.tokens)
        .toList(growable: false);
  }

  static List<String> get prefixTokens => tokensForType(.prefix);
  static List<String> get groupTokens => tokensForType(.group);
  static List<String> get postfixTokens => tokensForType(.postfix);
}

enum QuerySeverity { warning, error }

enum QueryIssueCode {
  missingSelectorValue,
  invalidSelectorValue,

  unexpectedToken,
  unclosedQuote,
  unclosedParenthesis,
  multiplicityViolation,
  unknownSelector,
}

class QueryParseIssue {
  const QueryParseIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.range,
  });

  final QueryIssueCode code;
  final QuerySeverity severity;
  final String message;
  final QueryRange? range;
}

@freezed
sealed class QueryCursorContext with _$QueryCursorContext {
  const factory QueryCursorContext.selectorKey({
    required int cursorOffset,
    required QueryRange activeRange,
    required String partialKey,
  }) = SelectorKeyCursorContext;

  const factory QueryCursorContext.selectorValue({
    required int cursorOffset,
    required QueryRange activeRange,
    required String selectorId,
    required String partialValue,
    required QueryRange keyRange,
    required QueryRange? valueRange,
  }) = SelectorValueCursorContext;

  const factory QueryCursorContext.operator({
    required int cursorOffset,
    required QueryRange activeRange,
    required String partialOperator,
  }) = OperatorCursorContext;

  const factory QueryCursorContext.unknown({
    required int cursorOffset,
    required QueryRange activeRange,
    required String partial,
    required QuerySide side,
  }) = UnknownCursorContext;
}

enum QuerySide { before, expression, after }

@freezed
sealed class QuerySuggestion with _$QuerySuggestion {
  const factory QuerySuggestion.selectorKey({
    required String label,
    required QueryRange replaceRange,
    required String selectorId,
  }) = SelectorKeySuggestion;

  const factory QuerySuggestion.selectorValue({
    required String label,
    required QueryRange replaceRange,
    required String selectorId,
    required String value,
  }) = SelectorValueSuggestion;

  const factory QuerySuggestion.operator({
    required String label,
    required QueryRange replaceRange,
    required String operatorToken,
  }) = OperatorSuggestion;
}

extension QuerySuggestionListX on List<QuerySuggestion> {
  String get key => fold("", (previousValue, element) {
    return "$previousValue${element.label}";
  });
}

class QueryParseResult {
  const QueryParseResult({
    required this.query,
    required this.queryBefore,
    required this.queryAfter,
    required this.raw,
    required this.expression,
    required this.tokens,
    required this.selectors,
    required this.issues,
    required this.cursorContext,
  });

  factory QueryParseResult.empty() => const QueryParseResult(
    query: "",
    queryBefore: "",
    queryAfter: "",
    raw: "",
    expression: null,
    tokens: <QueryLexerToken>[],
    selectors: <QueryLexerSelectorToken>[],
    issues: <QueryParseIssue>[],
    cursorContext: null,
  );

  /// Non selector text remainder, normalized from queryBefore and queryAfter.
  final String query;

  /// Non selector text that appears before the parsed expression.
  final String queryBefore;

  /// Non selector text that appears after the parsed expression.
  final String queryAfter;

  /// Original raw input string before parsing.
  final String raw;

  final QueryLexerToken? expression;
  final List<QueryLexerToken> tokens;
  final List<QueryLexerSelectorToken> selectors;
  final List<QueryParseIssue> issues;
  final QueryCursorContext? cursorContext;

  @override
  String toString() {
    return "QueryParseResult(query: '$query', queryBefore: '$queryBefore', queryAfter: '$queryAfter', raw: '$raw', expression: $expression, tokens: $tokens, selectors: $selectors, issues: $issues, cursorContext: $cursorContext)";
  }
}
