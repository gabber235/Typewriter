import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class StaticPresentationSearchSource implements SearchSource {
  StaticPresentationSearchSource({
    required this.provider,
    required this.expressions,
    required this.registry,
    required this.budget,
    required this.queryBindingId,
    required this.providerKey,
  });

  final StaticSearchProvider provider;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final BindingId queryBindingId;
  final String providerKey;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors =>
      Stream.value(presentationQuerySelectors(provider.selectors));

  @override
  void initialize() {
    scheduleMicrotask(() {
      if (!_disposed) {
        search(const SearchQueryContext(normalizedQuery: "", selectors: []));
      }
    });
  }

  @override
  void search(SearchQueryContext query) {
    if (_disposed) return;
    final context = presentationSearchContext(
      base: expressions,
      queryBindingId: queryBindingId,
      query: query,
      selectors: provider.selectors,
    );
    final evaluated = provider.values.evaluate(
      context,
      registry: registry,
      budget: budget,
    );
    if (evaluated case TypeFailure(:final diagnostics)) {
      _snapshots.add(_error(diagnostics));
      return;
    }
    final values = evaluated.valueOrNull!;
    if (values is! ListValue) {
      _snapshots.add(_message("Static search values must evaluate to a list"));
      return;
    }
    final itemType = _itemType(provider.values.resultType);
    final nodes = <SearchNode>[];
    final errors = <SearchErrorSummary>[];
    for (final value in values.values) {
      final mapped = _map(value, itemType, context);
      if (mapped case TypeFailure(:final diagnostics)) {
        errors.addAll(
          _summaries(diagnostics, severity: SearchErrorSeverity.warning),
        );
        continue;
      }
      nodes.add(SearchNode.result(result: mapped.valueOrNull!));
    }
    _snapshots.add(
      SearchSourceSnapshot.ready(nodes: nodes, errorSummaries: errors),
    );
  }

  TypeExpression _itemType(TypeExpression type) {
    if (type case ListType(:final element)) return element;
    if (type case NamedType()) {
      final resolved = registry.resolve(type).valueOrNull;
      if (resolved?.representation case ListType(:final element)) {
        return element;
      }
    }
    return const AnyType();
  }

  TypeResult<SearchResult> _map(
    DataValue value,
    TypeExpression type,
    ExpressionContext context,
  ) => PresentationSearchMapper(
    mapping: provider.result,
    registry: registry,
    budget: budget,
    providerKey: providerKey,
  ).map(value: value, type: type, expressions: context);

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Presentation results render their preview directly",
  );

  @override
  void dispose() {
    _disposed = true;
    unawaited(_snapshots.close());
  }

  SearchSourceSnapshot _error(List<TypeDiagnostic> diagnostics) =>
      SearchSourceSnapshot.error(errorSummaries: _summaries(diagnostics));

  SearchSourceSnapshot _message(String message) => SearchSourceSnapshot.error(
    errorSummaries: [
      SearchErrorSummary(
        id: "staticSearchInvalid",
        message: message,
        severity: SearchErrorSeverity.error,
      ),
    ],
  );

  List<SearchErrorSummary> _summaries(
    List<TypeDiagnostic> diagnostics, {
    SearchErrorSeverity severity = SearchErrorSeverity.error,
  }) => diagnostics.indexed
      .map(
        (entry) => SearchErrorSummary(
          id: "staticSearch.${entry.$1}",
          message: entry.$2.message,
          severity: severity,
        ),
      )
      .toList();
}
