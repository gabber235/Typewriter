// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_cursor.dart";
import "package:typewriter_panel/logic/search/query/query_grammar.dart";
import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";
import "package:typewriter_panel/logic/search/query/query_spans.dart";
import "package:typewriter_panel/logic/search/query/query_validation.dart";

export "query_ast.dart";
export "query_cursor.dart";
export "query_models.dart";
export "query_selector.dart";
export "query_spans.dart";
export "query_suggestions.dart";
export "query_validation.dart";

class QueryEngine {
  QueryEngine(List<QuerySelectorDefinition> selectors)
    : selectors = List.unmodifiable(selectors),
      _grammar = const QueryGrammar();

  final List<QuerySelectorDefinition> selectors;
  final QueryGrammar _grammar;

  QueryParseResult parse(String input, {int? cursorOffset}) {
    if (input.trim().isEmpty) {
      if (cursorOffset == null) {
        return QueryParseResult.empty();
      }
      final clamped = cursorOffset.clamp(0, input.length);
      return QueryParseResult(
        expression: null,
        selectorMatches: const <QuerySelectorMatch>[],
        textTerms: const <QueryTextTerm>[],
        leftoverText: "",
        issues: const <QueryParseIssue>[],
        cursorContext: UnknownCursorContext(
          cursorOffset: clamped,
          activeRange: QueryRange(clamped, clamped),
        ),
      );
    }

    final selectorMatches = <QuerySelectorMatch>[];
    final textTerms = <QueryTextTerm>[];
    final issues = <QueryParseIssue>[];

    _scanAtoms(
      input,
      selectorMatches: selectorMatches,
      textTerms: textTerms,
      issues: issues,
    );

    try {
      final grammarResult = _grammar.parse(
        input,
        selectorMatches: selectorMatches,
        textTerms: textTerms,
      );
      issues.addAll(grammarResult.issues);
      final validationResult = validateSelectorSemantics(
        matches: selectorMatches,
        selectors: selectors,
        textTerms: textTerms,
      );
      issues.addAll(validationResult.issues);

      QueryCursorContext? cursorContext;
      if (cursorOffset != null) {
        final provisional = QueryParseResult(
          expression: grammarResult.expression,
          selectorMatches: List.unmodifiable(selectorMatches),
          textTerms: List.unmodifiable(textTerms),
          leftoverText: textTerms.map((term) => term.text).join(" "),
          issues: List.unmodifiable(issues),
          cursorContext: null,
        );
        cursorContext = resolveQueryCursorContext(
          provisional,
          input,
          cursorOffset,
        );
      }

      return QueryParseResult(
        expression: grammarResult.expression,
        selectorMatches: List.unmodifiable(selectorMatches),
        textTerms: List.unmodifiable(textTerms),
        leftoverText: textTerms.map((term) => term.text).join(" "),
        issues: List.unmodifiable(issues),
        cursorContext: cursorContext,
      );
    } on Exception {
      issues.add(
        const QueryParseIssue(
          code: QueryIssueCode.unexpectedToken,
          message: "Failed to parse expression",
          severity: QuerySeverity.warning,
        ),
      );
      QueryCursorContext? cursorContext;
      if (cursorOffset != null) {
        final provisional = QueryParseResult(
          expression: null,
          selectorMatches: List.unmodifiable(selectorMatches),
          textTerms: List.unmodifiable(textTerms),
          leftoverText: textTerms.map((term) => term.text).join(" "),
          issues: List.unmodifiable(issues),
          cursorContext: null,
        );
        cursorContext = resolveQueryCursorContext(
          provisional,
          input,
          cursorOffset,
        );
      }

      return QueryParseResult(
        expression: null,
        selectorMatches: List.unmodifiable(selectorMatches),
        textTerms: List.unmodifiable(textTerms),
        leftoverText: textTerms.map((term) => term.text).join(" "),
        issues: List.unmodifiable(issues),
        cursorContext: cursorContext,
      );
    }
  }

  void _scanAtoms(
    String input, {
    required List<QuerySelectorMatch> selectorMatches,
    required List<QueryTextTerm> textTerms,
    required List<QueryParseIssue> issues,
  }) {
    var index = 0;
    while (index < input.length) {
      final char = input[index];
      if (_isWhitespace(char)) {
        index += 1;
        continue;
      }

      final symbolMatch = _tryParseSymbolSelector(input, index, issues);
      if (symbolMatch != null) {
        if (symbolMatch.match != null) {
          selectorMatches.add(symbolMatch.match!);
        } else {
          textTerms.add(symbolMatch.fallbackTerm!);
        }
        index = symbolMatch.nextIndex;
        continue;
      }

      final keyValueMatch = _tryParseKeyValueSelector(input, index, issues);
      if (keyValueMatch != null) {
        if (keyValueMatch.match != null) {
          selectorMatches.add(keyValueMatch.match!);
        } else {
          textTerms.add(keyValueMatch.fallbackTerm!);
        }
        index = keyValueMatch.nextIndex;
        continue;
      }

      if (_startsOperatorOrParenthesis(input, index)) {
        index = _consumeOperatorOrParenthesis(input, index);
        continue;
      }

      final termStart = index;
      while (index < input.length &&
          !_isWhitespace(input[index]) &&
          input[index] != "(" &&
          input[index] != ")") {
        index += 1;
      }
      final termText = input.substring(termStart, index);
      if (_isWordOperator(termText)) {
        continue;
      }

      textTerms.add(
        QueryTextTerm(text: termText, range: QueryRange(termStart, index)),
      );
    }
  }

  _AtomScanOutcome? _tryParseSymbolSelector(
    String input,
    int start,
    List<QueryParseIssue> issues,
  ) {
    final symbolSelectors = selectors.whereType<SymbolSelectorDefinition>();
    for (final selector in symbolSelectors) {
      if (!input.startsWith(selector.symbol, start)) {
        continue;
      }

      final tokenStart = start + selector.symbol.length;
      var end = tokenStart;
      while (end < input.length && !_isWhitespace(input[end])) {
        if (input[end] == "(" || input[end] == ")") {
          break;
        }
        end += 1;
      }

      final raw = input.substring(start, end);
      final token = input.substring(tokenStart, end);
      if (token.isEmpty) {
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.invalidSelectorValue,
            message: "Selector ${selector.id} is missing a token",
            severity: QuerySeverity.warning,
            range: QueryRange(start, end),
          ),
        );
        return _AtomScanOutcome(
          nextIndex: end,
          fallbackTerm: QueryTextTerm(text: raw, range: QueryRange(start, end)),
        );
      }

      return _AtomScanOutcome(
        nextIndex: end,
        match: SymbolSelectorMatch(
          selectorId: selector.id,
          rawText: raw,
          fullRange: QueryRange(start, end),
          symbol: selector.symbol,
          symbolRange: QueryRange(start, tokenStart),
          token: token,
          tokenRange: QueryRange(tokenStart, end),
        ),
      );
    }

    return null;
  }

  _AtomScanOutcome? _tryParseKeyValueSelector(
    String input,
    int start,
    List<QueryParseIssue> issues,
  ) {
    var cursor = start;
    while (cursor < input.length &&
        !_isWhitespace(input[cursor]) &&
        input[cursor] != ":") {
      if (input[cursor] == "(" || input[cursor] == ")") {
        return null;
      }
      cursor += 1;
    }

    if (cursor >= input.length || input[cursor] != ":") {
      return null;
    }

    final key = input.substring(start, cursor);
    if (key.isEmpty) {
      return null;
    }

    final keySelectors = selectors.whereType<KeyValueSelectorDefinition>();
    KeyValueSelectorDefinition? matchedSelector;
    for (final selector in keySelectors) {
      final keyMatches = selector.matchesKey(key);
      if (keyMatches) {
        matchedSelector = selector;
        break;
      }
    }

    if (matchedSelector == null) {
      return null;
    }

    final valueStart = cursor + 1;
    if (valueStart >= input.length) {
      issues.add(
        QueryParseIssue(
          code: QueryIssueCode.invalidSelectorValue,
          message: "Selector ${matchedSelector.id} is missing a value",
          severity: QuerySeverity.warning,
          range: QueryRange(start, valueStart),
        ),
      );
      return _AtomScanOutcome(
        nextIndex: valueStart,
        fallbackTerm: QueryTextTerm(
          text: input.substring(start, valueStart),
          range: QueryRange(start, valueStart),
        ),
      );
    }

    if (input[valueStart] == "\"") {
      final openQuote = valueStart;
      var closeQuote = openQuote + 1;
      while (closeQuote < input.length && input[closeQuote] != "\"") {
        closeQuote += 1;
      }

      if (closeQuote >= input.length) {
        final raw = input.substring(start);
        final value = input.substring(openQuote + 1);
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.unclosedQuote,
            message: "Selector ${matchedSelector.id} has an unclosed quote",
            severity: QuerySeverity.warning,
            range: QueryRange(openQuote, input.length),
            recoveryFragment: input.substring(openQuote),
          ),
        );
        return _AtomScanOutcome(
          nextIndex: input.length,
          match: KeyValueSelectorMatch(
            selectorId: matchedSelector.id,
            rawText: raw,
            fullRange: QueryRange(start, input.length),
            key: key,
            keyRange: QueryRange(start, cursor),
            value: value,
            valueRange: QueryRange(openQuote + 1, input.length),
            quoteRange: QueryRange(openQuote, input.length),
          ),
        );
      }

      final end = closeQuote + 1;
      final raw = input.substring(start, end);
      final value = input.substring(openQuote + 1, closeQuote);
      return _AtomScanOutcome(
        nextIndex: end,
        match: KeyValueSelectorMatch(
          selectorId: matchedSelector.id,
          rawText: raw,
          fullRange: QueryRange(start, end),
          key: key,
          keyRange: QueryRange(start, cursor),
          value: value,
          valueRange: QueryRange(openQuote + 1, closeQuote),
          quoteRange: QueryRange(openQuote, end),
        ),
      );
    }

    var end = valueStart;
    while (end < input.length && !_isWhitespace(input[end])) {
      if (input[end] == "(" || input[end] == ")") {
        break;
      }
      end += 1;
    }

    final raw = input.substring(start, end);
    final value = input.substring(valueStart, end);
    return _AtomScanOutcome(
      nextIndex: end,
      match: KeyValueSelectorMatch(
        selectorId: matchedSelector.id,
        rawText: raw,
        fullRange: QueryRange(start, end),
        key: key,
        keyRange: QueryRange(start, cursor),
        value: value,
        valueRange: QueryRange(valueStart, end),
        quoteRange: null,
      ),
    );
  }

  bool _startsOperatorOrParenthesis(String input, int start) {
    if (input.startsWith("&&", start) || input.startsWith("||", start)) {
      return true;
    }
    final char = input[start];
    return char == "!" || char == "(" || char == ")";
  }

  int _consumeOperatorOrParenthesis(String input, int start) {
    if (input.startsWith("&&", start) || input.startsWith("||", start)) {
      return start + 2;
    }
    return start + 1;
  }

  bool _isWordOperator(String token) {
    final lowered = token.toLowerCase();
    return lowered == "and" || lowered == "or" || lowered == "not";
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;
}

class Query {
  Query(List<QuerySelectorDefinition> selectors)
    : _engine = QueryEngine(selectors);
  final QueryEngine _engine;

  QueryParseResult parse(String query, {int? cursorOffset}) {
    return _engine.parse(query, cursorOffset: cursorOffset);
  }
}

class _AtomScanOutcome {
  const _AtomScanOutcome({
    required this.nextIndex,
    this.match,
    this.fallbackTerm,
  }) : assert(match != null || fallbackTerm != null);
  final int nextIndex;
  final QuerySelectorMatch? match;
  final QueryTextTerm? fallbackTerm;
}
