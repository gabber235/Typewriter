import "dart:async";

import "package:http/http.dart" as http;
import "package:typewriter_panel/typewriter_panel.dart";

final class PresentationSearchSourceFactory {
  const PresentationSearchSourceFactory({
    required this.client,
    required this.expressions,
    required this.registry,
    required this.budget,
    required this.queryBindingId,
    required this.selections,
    required this.historyStorage,
    this.collections = const {},
    this.realmSourceBuilder,
  });

  final http.Client client;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final BindingId queryBindingId;
  final Stream<PresentationSearchSelectionEvent> selections;
  final SearchHistoryStorage historyStorage;
  final Map<PresentationCollectionSourceId, PresentationCollectionSource>
  collections;
  final RealmPresentationSearchSourceBuilder? realmSourceBuilder;

  SearchSource build(SearchProvider provider, {String path = "root"}) =>
      switch (provider) {
        CollectionSearchProvider() => _collection(provider, path),
        StaticSearchProvider() => _static(provider, path),
        HttpJsonSearchProvider() => _http(provider, path),
        RealmCallbackSearchProvider() => _realm(provider, path),
        GatedSearchProvider(:final condition, :final guidance, :final child) =>
          build(child, path: "$path.gate").gated(
            (query) => _boolean(condition, query, child),
            closedGuidance: guidance == null
                ? null
                : (query) => SearchGuidance(
                    id: "$path.gate",
                    title: _text(guidance, query, child),
                  ),
          ),
        DebouncedSearchProvider(:final duration, :final child) => build(
          child,
          path: "$path.debounce",
        ).debounced(duration),
        CachedSearchProvider(
          :final capacity,
          :final retainStaleResults,
          :final child,
        ) =>
          build(
            child,
            path: "$path.cache",
          ).cached(capacity: capacity, retainStaleResults: retainStaleResults),
        RankedSearchProvider(:final fields, :final child) =>
          build(child, path: "$path.rank").ranked(
            fields
                .map(
                  (field) => SearchRankField(
                    text: (result) => _rankText(result, field.expression),
                    weight: field.weight,
                  ),
                )
                .toList(growable: false),
          ),
        LimitedSearchProvider(:final maximum, :final child) => build(
          child,
          path: "$path.limit",
        ).limited(_integer(maximum)),
        DistinctSearchProvider(:final child) => build(
          child,
          path: "$path.distinct",
        ).distinct(),
        HistoricalSearchProvider(
          :final key,
          :final label,
          :final capacity,
          :final child,
        ) =>
          build(child, path: "$path.history").withHistory(
            key: key,
            label: _text(label, _emptyQuery, child),
            capacity: capacity,
            storage: historyStorage,
            committedSelections: selections
                .where(
                  (event) => event.historyNamespace.startsWith("$path.history"),
                )
                .map((event) => event.result),
          ),
        SectionSearchProvider(:final id, :final label, :final child) => build(
          child,
          path: "$path.section",
        ).inSection(id: id, title: _text(label, _emptyQuery, child)),
        MergedSearchProvider(:final children) =>
          children.indexed
              .map((entry) => build(entry.$2, path: "$path.${entry.$1}"))
              .merged(),
      };

  SearchSource _collection(CollectionSearchProvider provider, String path) {
    _register(provider.result, path);
    final source = collections[provider.sourceId];
    if (source == null) {
      return UnavailableCollectionPresentationSearchSource(provider: provider);
    }
    return CollectionPresentationSearchSource(
      provider: provider,
      source: source,
      expressions: expressions,
      registry: registry,
      budget: budget,
      queryBindingId: queryBindingId,
      providerKey: path,
    );
  }

  SearchSource _static(StaticSearchProvider provider, String path) {
    _register(provider.result, path);
    return StaticPresentationSearchSource(
      provider: provider,
      expressions: expressions,
      registry: registry,
      budget: budget,
      queryBindingId: queryBindingId,
      providerKey: path,
    );
  }

  SearchSource _http(HttpJsonSearchProvider provider, String path) {
    _register(
      provider.result,
      path,
      contextBindingIds: provider.contextBindings.map(
        (binding) => binding.bindingId,
      ),
    );
    return HttpJsonPresentationSearchSource(
      provider: provider,
      client: client,
      expressions: expressions,
      registry: registry,
      budget: budget,
      queryBindingId: queryBindingId,
      providerKey: path,
    );
  }

  SearchSource _realm(RealmCallbackSearchProvider provider, String path) {
    _register(provider.result, path);
    final builder = realmSourceBuilder;
    if (builder == null) {
      return UnavailableRealmPresentationSearchSource(provider: provider);
    }
    return builder(
      provider: provider,
      queryBindingId: queryBindingId,
      expressions: expressions,
      registry: registry,
      budget: budget,
      providerKey: path,
    );
  }

  void _register(
    SearchResultMapping mapping,
    String providerKey, {
    Iterable<BindingId> contextBindingIds = const [],
  }) {
    final storage = historyStorage;
    if (storage is! PresentationSearchHistoryStorage) return;
    storage.register(
      providerKey: providerKey,
      mapping: mapping,
      contextBindingIds: contextBindingIds,
    );
  }

  bool _boolean(
    TypedExpression expression,
    SearchQueryContext query,
    SearchProvider child,
  ) {
    final value = _evaluate(expression, query, child).valueOrNull;
    return value is BooleanValue && value.value;
  }

  String _text(
    TypedExpression expression,
    SearchQueryContext query,
    SearchProvider child,
  ) =>
      _evaluate(expression, query, child).valueOrNull?.expressionDisplayText ??
      "Search";

  TypeResult<DataValue> _evaluate(
    TypedExpression expression,
    SearchQueryContext query,
    SearchProvider provider,
  ) => expression.evaluate(
    presentationSearchContext(
      base: expressions,
      queryBindingId: queryBindingId,
      query: query,
      selectors: provider.searchSelectors,
    ),
    registry: registry,
    budget: budget,
  );

  int _integer(TypedExpression expression) {
    final value = expression
        .evaluate(expressions, registry: registry, budget: budget)
        .valueOrNull;
    if (value is IntegerValue) return value.value.toInt().clamp(0, 100000);
    return 0;
  }

  String? _rankText(SearchResult result, TypedExpression expression) {
    final payload = result.payload;
    if (payload is! PresentationSearchResultPayload) return null;
    return expression
        .evaluate(payload.expressions, registry: registry, budget: budget)
        .valueOrNull
        ?.expressionDisplayText;
  }
}

const _emptyQuery = SearchQueryContext(normalizedQuery: "", selectors: []);

extension SearchProviderSelectors on SearchProvider {
  List<SearchSelectorDefinition> get searchSelectors => switch (this) {
    CollectionSearchProvider(:final selectors) ||
    StaticSearchProvider(:final selectors) ||
    HttpJsonSearchProvider(:final selectors) ||
    RealmCallbackSearchProvider(:final selectors) => selectors,
    GatedSearchProvider(:final child) ||
    DebouncedSearchProvider(:final child) ||
    CachedSearchProvider(:final child) ||
    RankedSearchProvider(:final child) ||
    LimitedSearchProvider(:final child) ||
    DistinctSearchProvider(:final child) ||
    HistoricalSearchProvider(:final child) ||
    SectionSearchProvider(:final child) => child.searchSelectors,
    MergedSearchProvider(:final children) =>
      children.expand((child) => child.searchSelectors).toList(growable: false),
  };
}
