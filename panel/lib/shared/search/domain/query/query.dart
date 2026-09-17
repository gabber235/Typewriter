import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

export "query_cursor.dart";
export "query_expression.dart";
export "query_lexer.dart";
export "query_models.dart";
export "query_selector.dart";
export "query_spans.dart";
export "query_suggestions.dart";

/// Parses search input against the selector definitions currently available.
///
/// Parsing returns both the normalized free text sent to sources and the
/// selector expression used for structured filtering. Cursor context and
/// issues are derived from the same parse, so query bar suggestions cannot
/// drift from search semantics.
class QueryEngine {
  QueryEngine(List<QuerySelectorDefinition> selectors)
    : selectors = List.unmodifiable(selectors),
      lexer = QueryLexer(selectors);

  final List<QuerySelectorDefinition> selectors;
  final QueryLexer lexer;

  /// Parses [input], optionally resolving the cursor at [cursorOffset].
  ///
  /// The offset is clamped to the input bounds. A null offset omits cursor
  /// context, which is useful for callers that only need search semantics.
  QueryParseResult parse(String input, {int? cursorOffset}) {
    final clamped = cursorOffset?.clamp(0, input.length);

    if (input.trim().isEmpty) {
      if (cursorOffset == null) {
        return QueryParseResult.empty();
      }
      return QueryParseResult(
        query: "",
        queryBefore: "",
        queryAfter: "",
        raw: input,
        expression: null,
        tokens: const [],
        selectors: const [],
        issues: const [],
        cursorContext: UnknownCursorContext(
          cursorOffset: clamped!,
          activeRange: QueryRange(clamped, clamped),
          partial: "",
          side: QuerySide.before,
        ),
      );
    }

    final result = lexer.tokenize(input);
    final tokens = result.expression?.flatten() ?? <QueryLexerToken>[];
    final issues = tokens.expand((token) => token.issues).toList()
      ..addAll(_booleanFreeTextIssues(input, result, this.selectors));
    final selectors = tokens.whereType<QueryLexerSelectorToken>().toList();

    final cursorContext = clamped != null
        ? resolveQueryCursorContext(tokens, input, clamped)
        : null;

    final selectorsById = selectors.groupListsBy((s) => s.selectorId);

    for (final selector in this.selectors) {
      final sel = selectorsById[selector.id];
      if (sel == null) {
        continue;
      }
      final i = selector.validate(sel);
      issues.addAll(i);
    }

    return QueryParseResult(
      query: result.query,
      queryBefore: result.queryBefore,
      queryAfter: result.queryAfter,
      raw: result.raw,
      expression: result.expression,
      tokens: List.unmodifiable(tokens),
      selectors: List.unmodifiable(selectors),
      issues: List.unmodifiable(issues),
      cursorContext: cursorContext,
    );
  }
}

List<QueryParseIssue> _booleanFreeTextIssues(
  String input,
  QueryLexerResult result,
  List<QuerySelectorDefinition> selectors,
) {
  if (result.expression == null) return const [];
  final issues = <QueryParseIssue>[];
  final trailing = RegExp(
    r"^(?:AND\b|OR\b|&&|\|\|)\s+(.+)$",
    caseSensitive: false,
  ).firstMatch(result.queryAfter);
  if (trailing != null &&
      !_couldBecomeSelectorOperand(trailing.group(1)!, selectors)) {
    final start = input.lastIndexOf(result.queryAfter);
    issues.add(
      QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        severity: QuerySeverity.error,
        message: "Boolean operators can only combine selectors",
        range: QueryRange(start, start + trailing.end),
      ),
    );
  }

  final leading = RegExp(
    r"^(.+?)\s+(?:AND\b|OR\b|&&|\|\|)$",
    caseSensitive: false,
  ).firstMatch(result.queryBefore);
  if (leading != null &&
      !_couldBecomeSelectorOperand(leading.group(1)!, selectors)) {
    final start = input.indexOf(result.queryBefore) + leading.start;
    issues.add(
      QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        severity: QuerySeverity.error,
        message: "Boolean operators can only combine selectors",
        range: QueryRange(start, start + leading.group(0)!.length),
      ),
    );
  }
  return issues;
}

bool _couldBecomeSelectorOperand(
  String input,
  List<QuerySelectorDefinition> selectors,
) {
  var candidate = input.trimLeft();
  while (true) {
    final prefix = RegExp(
      r"^(?:(?:NOT\b|!)\s*|\(\s*)",
      caseSensitive: false,
    ).firstMatch(candidate);
    if (prefix == null) break;
    candidate = candidate.substring(prefix.end);
  }
  if (candidate.isEmpty) return true;
  return selectors.any((selector) {
    final key = switch (selector) {
      KeyValueSelectorDefinition(:final key) => key,
    };
    return selector.caseSensitive
        ? key.startsWith(candidate)
        : key.toLowerCase().startsWith(candidate.toLowerCase());
  });
}

/// Small facade for parsing queries without exposing the lexer lifecycle.
class Query {
  Query(List<QuerySelectorDefinition> selectors)
    : _engine = QueryEngine(selectors);
  final QueryEngine _engine;

  /// Parses [query] using the selector definitions supplied at construction.
  QueryParseResult parse(String query, {int? cursorOffset}) {
    return _engine.parse(query, cursorOffset: cursorOffset);
  }
}
