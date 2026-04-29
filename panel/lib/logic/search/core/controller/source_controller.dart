import "dart:async";

import "package:flutter/foundation.dart";
import "package:typewriter_panel/logic/search/search.dart";

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

  late StreamSubscription<SearchSourceSnapshot> _sourceSubscription;
  late StreamSubscription<List<QuerySelectorDefinition>> _selectorSubscription;

  void updateQuery(String rawQuery) {
    _lastRawQuery = rawQuery;

    final selectorsById = {for (final s in selectors) s.id: s};
    final query = Query(selectors);
    final result = query.parse(rawQuery);

    final newContext = SearchQueryContext(
      normalizedQuery: result.query,
      selectors: result.selectors.map((s) {
        assert(selectorsById.containsKey(s.selectorId), "Unknown selector");
        return switch (s) {
          QueryLexerKeyValueSelectorToken(:final selectorId, :final value) =>
            SearchParsedSelector(
              selectorId: selectorId,
              key: (selectorsById[selectorId]! as KeyValueSelectorDefinition)
                  .key,
              value: value,
            ),
          QueryLexerSelectorToken() => throw StateError(
            "Unexpected selector token",
          ),
        };
      }).toList(),
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
