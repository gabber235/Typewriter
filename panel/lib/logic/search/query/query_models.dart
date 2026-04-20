// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_ast.dart";
import "package:typewriter_panel/logic/search/query/query_spans.dart";

enum QuerySeverity { warning, error }

enum QueryIssueCode {
  unexpectedToken,
  unclosedQuote,
  unclosedParenthesis,
  invalidSelectorValue,
  multiplicityViolation,
  unknownSelector,
}

class QueryParseIssue {
  final QueryIssueCode code;
  final String message;
  final QuerySeverity severity;
  final QueryRange? range;
  final String? recoveryFragment;

  const QueryParseIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.range,
    this.recoveryFragment,
  });
}

class QueryTextTerm {
  final String text;
  final QueryRange range;

  const QueryTextTerm({required this.text, required this.range});
}

sealed class QuerySelectorMatch {
  final String selectorId;
  final String rawText;
  final QueryRange fullRange;

  const QuerySelectorMatch({
    required this.selectorId,
    required this.rawText,
    required this.fullRange,
  });
}

final class SymbolSelectorMatch extends QuerySelectorMatch {
  final String symbol;
  final QueryRange symbolRange;
  final String token;
  final QueryRange tokenRange;

  const SymbolSelectorMatch({
    required super.selectorId,
    required super.rawText,
    required super.fullRange,
    required this.symbol,
    required this.symbolRange,
    required this.token,
    required this.tokenRange,
  });
}

final class KeyValueSelectorMatch extends QuerySelectorMatch {
  final String key;
  final QueryRange keyRange;
  final String? value;
  final QueryRange? valueRange;
  final QueryRange? quoteRange;

  const KeyValueSelectorMatch({
    required super.selectorId,
    required super.rawText,
    required super.fullRange,
    required this.key,
    required this.keyRange,
    required this.value,
    required this.valueRange,
    required this.quoteRange,
  });
}

sealed class QueryCursorContext {
  final int cursorOffset;
  final QueryRange activeRange;

  const QueryCursorContext({
    required this.cursorOffset,
    required this.activeRange,
  });
}

final class SelectorKeyCursorContext extends QueryCursorContext {
  final String partialKey;

  const SelectorKeyCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partialKey,
  });
}

final class SelectorValueCursorContext extends QueryCursorContext {
  final String selectorId;
  final String partialValue;
  final QueryRange keyRange;
  final QueryRange? valueRange;

  const SelectorValueCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.selectorId,
    required this.partialValue,
    required this.keyRange,
    required this.valueRange,
  });
}

final class OperatorCursorContext extends QueryCursorContext {
  final String partialOperator;

  const OperatorCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partialOperator,
  });
}

final class TextTermCursorContext extends QueryCursorContext {
  final String partialText;

  const TextTermCursorContext({
    required super.cursorOffset,
    required super.activeRange,
    required this.partialText,
  });
}

final class UnknownCursorContext extends QueryCursorContext {
  const UnknownCursorContext({
    required super.cursorOffset,
    required super.activeRange,
  });
}

sealed class QuerySuggestion {
  final String label;
  final QueryRange replaceRange;

  const QuerySuggestion({required this.label, required this.replaceRange});
}

final class SelectorKeySuggestion extends QuerySuggestion {
  final String selectorId;

  const SelectorKeySuggestion({
    required super.label,
    required super.replaceRange,
    required this.selectorId,
  });
}

final class SelectorValueSuggestion extends QuerySuggestion {
  final String selectorId;
  final String value;

  const SelectorValueSuggestion({
    required super.label,
    required super.replaceRange,
    required this.selectorId,
    required this.value,
  });
}

final class OperatorSuggestion extends QuerySuggestion {
  final String operatorToken;

  const OperatorSuggestion({
    required super.label,
    required super.replaceRange,
    required this.operatorToken,
  });
}

extension QuerySuggestionListX on List<QuerySuggestion> {
  String get key => fold("", (previousValue, element) {
    return "$previousValue${element.label}";
  });
}

class QueryParseResult {
  final QueryExpressionNode? expression;
  final List<QuerySelectorMatch> selectorMatches;
  final List<QueryTextTerm> textTerms;
  final String leftoverText;
  final List<QueryParseIssue> issues;
  final QueryCursorContext? cursorContext;

  const QueryParseResult({
    required this.expression,
    required this.selectorMatches,
    required this.textTerms,
    required this.leftoverText,
    required this.issues,
    required this.cursorContext,
  });

  factory QueryParseResult.empty() => const QueryParseResult(
    expression: null,
    selectorMatches: <QuerySelectorMatch>[],
    textTerms: <QueryTextTerm>[],
    leftoverText: "",
    issues: <QueryParseIssue>[],
    cursorContext: null,
  );
}
