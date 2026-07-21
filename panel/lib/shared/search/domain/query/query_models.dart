import "package:typewriter_panel/typewriter_panel.dart";

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

sealed class QueryCursorContext {
  const QueryCursorContext({
    required this.cursorOffset,
    required this.activeRange,
  });
  final int cursorOffset;
  final QueryRange activeRange;
}

final class SelectorKeyCursorContext extends QueryCursorContext {
  const SelectorKeyCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partialKey,
  });

  final String partialKey;
}

final class SelectorValueCursorContext extends QueryCursorContext {
  const SelectorValueCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.selectorId,
    required this.partialValue,
    required this.keyRange,
    required this.valueRange,
  });

  final String selectorId;
  final String partialValue;
  final QueryRange keyRange;
  final QueryRange? valueRange;
}

final class OperatorCursorContext extends QueryCursorContext {
  const OperatorCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partialOperator,
  });

  final String partialOperator;
}

final class UnknownCursorContext extends QueryCursorContext {
  const UnknownCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partial,
    required this.side,
  });

  final String partial;

  final QuerySide side;
}

enum QuerySide { before, expression, after }

sealed class QuerySuggestion {
  const QuerySuggestion({required this.label, required this.replaceRange});

  final String label;
  final QueryRange replaceRange;

  @override
  String toString() {
    return "QuerySuggestion(label: '$label', replaceRange: $replaceRange)";
  }
}

final class SelectorKeySuggestion extends QuerySuggestion {
  const SelectorKeySuggestion({
    required super.label,
    required super.replaceRange,
    required this.selectorId,
  });

  final String selectorId;

  @override
  String toString() {
    return "SelectorKeySuggestion(label: '$label', replaceRange: $replaceRange, selectorId: '$selectorId')";
  }
}

final class SelectorValueSuggestion extends QuerySuggestion {
  const SelectorValueSuggestion({
    required super.label,
    required super.replaceRange,
    required this.selectorId,
    required this.value,
  });

  final String selectorId;
  final String value;

  @override
  String toString() {
    return "SelectorValueSuggestion(label: '$label', replaceRange: $replaceRange, selectorId: '$selectorId', value: '$value')";
  }
}

final class OperatorSuggestion extends QuerySuggestion {
  const OperatorSuggestion({
    required super.label,
    required super.replaceRange,
    required this.operatorToken,
  });

  final String operatorToken;

  @override
  String toString() {
    return "OperatorSuggestion(label: '$label', replaceRange: $replaceRange, operatorToken: '$operatorToken')";
  }
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
