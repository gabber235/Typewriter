part of "portable_search_compiler.dart";

final class _PortableCustomSearchSource implements SearchSource {
  _PortableCustomSearchSource({
    required this.expression,
    required this.evaluation,
    required Iterable<skir.SearchSelectorDefinition> selectors,
  }) : selectorDefinitions = List.unmodifiable(selectors),
       selectors = List.unmodifiable(selectors.map(_querySelector));

  final skir.ExpressionNode expression;
  final _PortableSearchEvaluation evaluation;
  final List<skir.SearchSelectorDefinition> selectorDefinitions;
  @override
  final List<QuerySelectorDefinition> selectors;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (context.normalizedQuery.isEmpty) {
      _snapshots.add(SearchSourceSnapshot.ready(nodes: const []));
      return;
    }
    final evaluated = evaluation.evaluate(
      expression,
      query: context,
      selectors: selectorDefinitions,
    );
    if (evaluated is! PortableExpressionAvailable) {
      _snapshots.add(SearchSourceSnapshot.ready(nodes: const []));
      return;
    }
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          SearchNode.result(
            result: SearchResult(
              id: "custom:${canonicalAuthoredValue(evaluated.value)}",
              type: portableSearchResultType,
              payload: PortableSearchPayload.custom(
                selectedValue: evaluated.value,
                providerPath: "custom",
                query: context,
              ),
              title: context.normalizedQuery,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(
        const SearchPreviewRequestResult.error(
          message: "Custom values have no separate preview",
        ),
      );

  @override
  void dispose() => unawaited(_snapshots.close());
}

abstract base class _PortableLeafSearchSource implements SearchSource {
  _PortableLeafSearchSource({
    required this.evaluation,
    required this.providerPath,
    required Iterable<skir.SearchSelectorDefinition> selectorDefinitions,
  }) : selectorDefinitions = List.unmodifiable(selectorDefinitions),
       selectors = List.unmodifiable(selectorDefinitions.map(_querySelector));

  final _PortableSearchEvaluation evaluation;
  final String providerPath;
  final List<skir.SearchSelectorDefinition> selectorDefinitions;
  @override
  final List<QuerySelectorDefinition> selectors;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);
  bool disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(
        const SearchPreviewRequestResult.error(
          message: "Portable search results have no separate preview",
        ),
      );

  void emit(SearchSourceSnapshot snapshot) {
    if (!disposed) _snapshots.add(snapshot);
  }

  List<SearchNode> mapValues(
    Iterable<skir.DataValue> values,
    skir.SearchResultMapping mapping,
    SearchQueryContext query,
  ) => values
      .map(
        (value) => evaluation.mapResult(
          value,
          mapping,
          query,
          selectorDefinitions,
          providerPath,
        ),
      )
      .nonNulls
      .map((result) => SearchNode.result(result: result))
      .toList(growable: false);

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    unawaited(_snapshots.close());
  }
}

final class _PortableStaticSearchSource extends _PortableLeafSearchSource {
  _PortableStaticSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.StaticSearchProvider provider;

  @override
  void search(SearchQueryContext context) {
    final result = evaluation.evaluate(
      provider.values,
      query: context,
      selectors: selectorDefinitions,
    );
    if (result case PortableExpressionAvailable(:final value)) {
      final items = value.authoredItems;
      if (items != null) {
        emit(
          SearchSourceSnapshot.ready(
            nodes: mapValues(
              items.map((item) => item.value),
              provider.result,
              context,
            ),
          ),
        );
        return;
      }
    }
    emit(_searchError(providerPath, "Static search values are unavailable"));
  }
}

final class _PortableCollectionSearchSource extends _PortableLeafSearchSource {
  _PortableCollectionSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.CollectionSearchProvider provider;

  @override
  void search(SearchQueryContext context) {
    final environment = evaluation.environment;
    final host = environment.collectionHost;
    final material = environment.material;
    if (host == null || material == null) {
      emit(_searchError(providerPath, "Collection search is unavailable"));
      return;
    }
    final projection = host.projectCollection(
      provider.sourceId,
      material: material,
      context: environment.context,
    );
    if (projection.problem case final problem?) {
      emit(_searchError(providerPath, problem));
      return;
    }
    final rows = provider.where == null
        ? projection.rows
        : projection.rows.where((row) {
            return _boolean(
              evaluation.evaluate(
                provider.where!,
                query: context,
                selectors: selectorDefinitions,
                row: (provider.result.binding, row.row),
              ),
            );
          });
    emit(
      SearchSourceSnapshot.ready(
        nodes: [
          for (final row in rows)
            if (evaluation.mapResult(
                  row.row,
                  provider.result,
                  context,
                  selectorDefinitions,
                  providerPath,
                )
                case final result?)
              SearchNode.result(result: result),
        ],
      ),
    );
  }
}

final class _PortableUnavailableSearchSource implements SearchSource {
  _PortableUnavailableSearchSource({required this.message});

  final String message;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) =>
      _snapshots.add(_searchError("unavailable", message));

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(SearchPreviewRequestResult.error(message: message));

  @override
  void dispose() => unawaited(_snapshots.close());
}
