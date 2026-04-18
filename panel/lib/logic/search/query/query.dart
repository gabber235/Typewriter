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

    final issues = <QueryParseIssue>[];

    try {
      final grammarResult = _grammar.parse(input, selectors: selectors);
      issues.addAll(grammarResult.issues);
      final validationResult = validateSelectorSemantics(
        matches: grammarResult.selectorMatches,
        selectors: selectors,
        textTerms: grammarResult.textTerms,
      );
      issues.addAll(validationResult.issues);

      QueryCursorContext? cursorContext;
      if (cursorOffset != null) {
        final provisional = QueryParseResult(
          expression: grammarResult.expression,
          selectorMatches: List.unmodifiable(grammarResult.selectorMatches),
          textTerms: List.unmodifiable(grammarResult.textTerms),
          leftoverText: grammarResult.textTerms.map((term) => term.text).join(" "),
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
        selectorMatches: List.unmodifiable(grammarResult.selectorMatches),
        textTerms: List.unmodifiable(grammarResult.textTerms),
        leftoverText: grammarResult.textTerms.map((term) => term.text).join(" "),
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
          selectorMatches: const <QuerySelectorMatch>[],
          textTerms: const <QueryTextTerm>[],
          leftoverText: "",
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
        selectorMatches: const <QuerySelectorMatch>[],
        textTerms: const <QueryTextTerm>[],
        leftoverText: "",
        issues: List.unmodifiable(issues),
        cursorContext: cursorContext,
      );
    }
  }
}

class Query {
  Query(List<QuerySelectorDefinition> selectors)
    : _engine = QueryEngine(selectors);
  final QueryEngine _engine;

  QueryParseResult parse(String query, {int? cursorOffset}) {
    return _engine.parse(query, cursorOffset: cursorOffset);
  }
}
