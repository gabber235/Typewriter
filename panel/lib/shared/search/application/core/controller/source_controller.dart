import "dart:async";

import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SourceController extends ChangeNotifier {
  SourceController({
    required this.source,
    required this.baseSelectors,
    String initialQuery = "",
  }) : _mergedSelectors = List.unmodifiable(baseSelectors) {
    _lastRawQuery = initialQuery;
    _lastSearchedContext = SearchQueryContext(
      normalizedQuery: initialQuery,
      selectors: [],
    );

    source.initialize();

    _sourceSubscription = source.snapshots.listen(_onSourceSnapshot);
    _selectorSubscription = source.selectors.listen(_onSelectors);
  }

  final SearchSource source;
  final List<QuerySelectorDefinition> baseSelectors;

  SearchSourceSnapshot _snapshot = SearchSourceSnapshot.idle();
  SearchSourceSnapshot get snapshot => _snapshot;

  List<QuerySelectorDefinition> _mergedSelectors;
  List<QuerySelectorDefinition> get selectors => _mergedSelectors;

  late String _lastRawQuery;
  late SearchQueryContext _lastSearchedContext;
  String get query => _lastRawQuery;
  SearchQueryContext get queryContext => _lastSearchedContext;

  late StreamSubscription<SearchSourceSnapshot> _sourceSubscription;
  late StreamSubscription<List<QuerySelectorDefinition>> _selectorSubscription;

  void updateQuery(String rawQuery) {
    _lastRawQuery = rawQuery;

    final selectorsById = {for (final s in selectors) s.id: s};
    final query = Query(selectors);
    final result = query.parse(rawQuery);
    final parsedSelectors = result.selectors.map((s) {
      assert(selectorsById.containsKey(s.selectorId), "Unknown selector");
      return _parsedSelector(s, selectorsById);
    }).toList();

    final newContext = SearchQueryContext(
      normalizedQuery: result.query,
      selectors: parsedSelectors,
      selectorExpression: _selectorExpression(result.expression, selectorsById),
    );

    if (newContext == _lastSearchedContext) {
      return;
    }

    _lastSearchedContext = newContext;
    triggerQuery();
  }

  void triggerQuery() {
    source.search(_lastSearchedContext);
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

  void _onSourceSnapshot(SearchSourceSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  void _onSelectors(List<QuerySelectorDefinition> selectors) {
    _mergedSelectors = baseSelectors.merge(selectors);
    updateQuery(_lastRawQuery);
  }

  @override
  void dispose() {
    super.dispose();

    _sourceSubscription.cancel();
    _selectorSubscription.cancel();
    source.dispose();
  }
}
