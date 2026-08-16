import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class CollectionPresentationSearchSource implements SearchSource {
  CollectionPresentationSearchSource({
    required this.provider,
    required this.source,
    required this.expressions,
    required this.registry,
    required this.budget,
    required this.queryBindingId,
    required this.providerKey,
  });

  final CollectionSearchProvider provider;
  final PresentationCollectionSource source;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final BindingId queryBindingId;
  final String providerKey;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  StreamSubscription<PresentationCollectionSnapshot>? _subscription;
  bool _disposed = false;
  int _searchGeneration = 0;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors =>
      Stream.value(presentationQuerySelectors(provider.selectors));

  @override
  void initialize() => search(_emptyQuery);

  @override
  void search(SearchQueryContext query) {
    if (_disposed) return;
    final generation = ++_searchGeneration;
    unawaited(_subscription?.cancel());
    _snapshots.add(SearchSourceSnapshot.loading());
    _subscription = source
        .watch(PresentationCollectionQuery.search(query))
        .listen((snapshot) => _emit(snapshot, query, generation));
  }

  void _emit(
    PresentationCollectionSnapshot snapshot,
    SearchQueryContext query,
    int generation,
  ) {
    if (_disposed || generation != _searchGeneration) return;
    if (snapshot.loading) {
      _snapshots.add(SearchSourceSnapshot.loading());
      return;
    }
    final context = presentationSearchContext(
      base: expressions,
      queryBindingId: queryBindingId,
      query: query,
      selectors: provider.selectors,
    );
    final rows = <SearchNode>[];
    final errors = <SearchErrorSummary>[
      for (final entry in snapshot.diagnostics.indexed)
        SearchErrorSummary(
          id: "collection.$providerKey.${entry.$1}",
          message: entry.$2.message,
          severity: SearchErrorSeverity.warning,
        ),
    ];
    for (final row in snapshot.rows) {
      final rowSnapshot = BindingSnapshot(
        type: source.schema.rowType,
        value: row.value,
        revision: 0,
        writable: false,
      );
      final rowContext = context.withBinding(
        source.schema.rowBindingId,
        rowSnapshot,
      );
      final candidateContext = rowContext.withBinding(
        provider.result.bindingId,
        rowSnapshot,
      );
      final condition = provider.where?.evaluate(
        candidateContext,
        registry: registry,
        budget: budget,
      );
      if (condition != null &&
          condition.valueOrNull != const BooleanValue(true)) {
        errors.addAll(_errors(condition.diagnostics));
        continue;
      }
      final mapped =
          PresentationSearchMapper(
            mapping: provider.result,
            registry: registry,
            budget: budget,
            providerKey: providerKey,
          ).map(
            value: row.value,
            type: source.schema.rowType,
            expressions: rowContext,
          );
      if (mapped case TypeFailure(:final diagnostics)) {
        errors.addAll(_errors(diagnostics));
        continue;
      }
      rows.add(SearchNode.result(result: mapped.valueOrNull!));
    }
    _snapshots.add(
      SearchSourceSnapshot.ready(nodes: rows, errorSummaries: errors),
    );
  }

  List<SearchErrorSummary> _errors(List<TypeDiagnostic> diagnostics) =>
      diagnostics.indexed
          .map(
            (entry) => SearchErrorSummary(
              id: "collection.$providerKey.map.${entry.$1}",
              message: entry.$2.message,
              severity: SearchErrorSeverity.warning,
            ),
          )
          .toList(growable: false);

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Presentation results render their preview directly",
  );

  @override
  void dispose() {
    _disposed = true;
    _searchGeneration++;
    unawaited(_subscription?.cancel());
    unawaited(_snapshots.close());
  }
}

final class UnavailableCollectionPresentationSearchSource
    implements SearchSource {
  const UnavailableCollectionPresentationSearchSource({required this.provider});

  final CollectionSearchProvider provider;

  @override
  Stream<SearchSourceSnapshot> get snapshots => Stream.value(
    SearchSourceSnapshot.error(
      errorSummaries: [
        SearchErrorSummary(
          id: "collection.unavailable",
          message: "Collection source is unavailable",
          severity: SearchErrorSeverity.error,
        ),
      ],
    ),
  );

  @override
  Stream<List<QuerySelectorDefinition>> get selectors =>
      Stream.value(presentationQuerySelectors(provider.selectors));

  @override
  void initialize() {}

  @override
  void search(SearchQueryContext query) {}

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Collection source is unavailable",
  );

  @override
  void dispose() {}
}

const _emptyQuery = SearchQueryContext(normalizedQuery: "", selectors: []);
