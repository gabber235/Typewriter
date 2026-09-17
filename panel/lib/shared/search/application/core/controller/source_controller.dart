import "dart:async";

import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns raw query text and the parsed context sent to a [SearchSource].
///
/// Selector updates are merged with [baseSelectors]. A changed parsed context
/// triggers one source search, so callers should use [updateQuery] for user
/// input and [triggerQuery] only when the same context must be reissued.
class SourceController extends ChangeNotifier {
  SourceController({
    required this.source,
    required this.baseSelectors,
    String initialQuery = "",
  }) : _mergedSelectors = List.unmodifiable(
         baseSelectors.merge(source.selectors),
       ) {
    _lastRawQuery = initialQuery;
    _lastSearchedContext = _parseContext(initialQuery);

    source.initialize(_lastSearchedContext);

    _sourceSubscription = source.snapshots.listen(_onSourceSnapshot);
  }

  final SearchSource source;
  final List<QuerySelectorDefinition> baseSelectors;

  SearchSourceSnapshot _snapshot = SearchSourceSnapshot.idle();
  SearchSourceSnapshot get snapshot => _snapshot;

  final List<QuerySelectorDefinition> _mergedSelectors;
  List<QuerySelectorDefinition> get selectors => _mergedSelectors;

  late String _lastRawQuery;
  late SearchQueryContext _lastSearchedContext;
  String get query => _lastRawQuery;
  SearchQueryContext get queryContext => _lastSearchedContext;
  QueryParseResult _lastParseResult = QueryParseResult.empty();

  List<QueryParseIssue> get validationIssues {
    final rejected = snapshot.selectorValidations
        .where((item) => item.status == SearchSelectorValidationStatus.rejected)
        .toList();
    if (rejected.isEmpty) return const [];

    return _lastParseResult.selectors
        .whereType<QueryLexerKeyValueSelectorToken>()
        .map((token) {
          final value = token.value;
          if (value == null) return null;
          final definition = selectors
              .whereType<KeyValueSelectorDefinition>()
              .firstWhere((item) => item.id == token.selectorId);
          final matches = rejected.any(
            (item) =>
                item.selectorId == token.selectorId &&
                (definition.caseSensitive
                    ? item.value == value
                    : item.value.toLowerCase() == value.toLowerCase()),
          );
          if (!matches) return null;
          return QueryParseIssue(
            code: QueryIssueCode.invalidSelectorValue,
            severity: QuerySeverity.error,
            message: "Unknown value $value for selector ${token.selectorId}",
            range: token.valueRange,
          );
        })
        .nonNulls
        .toList(growable: false);
  }

  late StreamSubscription<SearchSourceSnapshot> _sourceSubscription;

  /// Parses [rawQuery], updates the authoritative query context, and searches
  /// when the parsed context differs from the previous search.
  void updateQuery(String rawQuery) {
    _lastRawQuery = rawQuery;
    final newContext = _parseContext(rawQuery);

    if (newContext == _lastSearchedContext) {
      return;
    }

    _lastSearchedContext = newContext;
    triggerQuery();
  }

  SearchQueryContext _parseContext(String rawQuery) {
    final selectorsById = {
      for (final selector in selectors) selector.id: selector,
    };
    final result = Query(selectors).parse(rawQuery);
    _lastParseResult = result;
    final parsedSelectors = result.selectors.map((selector) {
      assert(
        selectorsById.containsKey(selector.selectorId),
        "Unknown selector",
      );
      return _parsedSelector(selector, selectorsById);
    }).toList();

    return SearchQueryContext(
      normalizedQuery: result.query,
      terms: _searchTerms(result.query),
      selectors: parsedSelectors,
      selectorExpression: _selectorExpression(result.expression, selectorsById),
    );
  }

  /// Reissues the last parsed context without reparsing the raw query.
  void triggerQuery() {
    source.search(_lastSearchedContext);
  }

  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) {
    final completer = source;
    if (completer is! SearchSelectorCompletionSource) {
      return Future.value(const SearchSelectorCompletionResult());
    }
    return (completer as SearchSelectorCompletionSource).completeSelector(
      request,
    );
  }

  SearchParsedSelector _parsedSelector(
    QueryLexerSelectorToken token,
    Map<String, QuerySelectorDefinition> selectorsById,
  ) {
    return switch (token) {
      QueryLexerKeyValueSelectorToken(:final selectorId, :final value) =>
        SearchParsedSelector(
          selectorId: selectorId,
          key: (selectorsById[selectorId]! as KeyValueSelectorDefinition).key,
          value: value,
        ),
      QueryLexerSelectorToken() => throw StateError(
        "Unexpected selector token",
      ),
    };
  }

  SearchSelectorExpression? _selectorExpression(
    QueryLexerToken? token,
    Map<String, QuerySelectorDefinition> selectorsById,
  ) {
    return switch (token) {
      null => null,
      QueryLexerKeyValueSelectorToken() => SearchSelectorLeafExpression(
        _parsedSelector(token, selectorsById),
      ),
      QueryLexerOperatorToken(:final type, :final left, :final right) =>
        SearchSelectorBinaryExpression(
          operator: switch (type) {
            QueryLexerOperatorType.and => SearchSelectorOperator.and,
            QueryLexerOperatorType.or => SearchSelectorOperator.or,
          },
          left: _selectorExpression(left, selectorsById)!,
          right: _selectorExpression(right, selectorsById)!,
        ),
      QueryLexerNegationToken(:final token) => SearchSelectorNotExpression(
        _selectorExpression(token, selectorsById)!,
      ),
      QueryLexerSelectorToken() => throw StateError(
        "Unexpected selector token",
      ),
    };
  }

  /// Forwards the latest child snapshot to listeners as the source projection.
  void _onSourceSnapshot(SearchSourceSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  /// Cancels subscriptions and transfers disposal to the owned source.
  @override
  void dispose() {
    super.dispose();

    _sourceSubscription.cancel();
    source.dispose();
  }
}

final _searchTermPattern = RegExp(r"[\p{L}\p{N}_]+", unicode: true);

List<String> _searchTerms(String query) => _searchTermPattern
    .allMatches(query.toLowerCase())
    .map((match) => match.group(0)!)
    .take(12)
    .toSet()
    .toList(growable: false);
