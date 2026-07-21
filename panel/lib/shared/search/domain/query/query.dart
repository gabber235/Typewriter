import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

export "query_cursor.dart";
export "query_lexer.dart";
export "query_models.dart";
export "query_selector.dart";
export "query_spans.dart";
export "query_suggestions.dart";

class QueryEngine {
  QueryEngine(List<QuerySelectorDefinition> selectors)
    : selectors = List.unmodifiable(selectors),
      lexer = QueryLexer(selectors);

  final List<QuerySelectorDefinition> selectors;
  final QueryLexer lexer;

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
    final issues = tokens.expand((token) => token.issues).toList();
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

class Query {
  Query(List<QuerySelectorDefinition> selectors)
    : _engine = QueryEngine(selectors);
  final QueryEngine _engine;

  QueryParseResult parse(String query, {int? cursorOffset}) {
    return _engine.parse(query, cursorOffset: cursorOffset);
  }
}
