import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Immutable capabilities captured by one portable search composition.
///
/// The HTTP client and history storage are borrowed. The source graph owns
/// every subscription it creates and never disposes these borrowed values.
final class PortableSearchEnvironment {
  const PortableSearchEnvironment({
    required this.catalog,
    required this.budget,
    required this.context,
    required this.http,
    required this.historyStorage,
    required this.historyNamespace,
    this.watchRealm,
    this.collectionHost,
    this.material,
    this.subject,
  });

  final CheckedEditorCatalog catalog;
  final skir.EvaluationBudget budget;
  final PortableInvocationContext context;
  final Client http;
  final SearchHistoryStorage historyStorage;
  final String historyNamespace;
  final Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest request,
  )?
  watchRealm;
  final PortableCollectionProjectionHost? collectionHost;
  final skir.PresentationMaterial? material;

  /// The subject of [material], whose type arguments close the templates of
  /// the bindings the search declares.
  final skir.TypeSelection? subject;

  /// A copy whose invocation context also binds [bindings].
  PortableSearchEnvironment withBindings(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
  ) => PortableSearchEnvironment(
    catalog: catalog,
    budget: budget,
    context: context.withBindings(bindings),
    http: http,
    historyStorage: historyStorage,
    historyNamespace: historyNamespace,
    watchRealm: watchRealm,
    collectionHost: collectionHost,
    material: material,
    subject: subject,
  );

  /// The type [template] declares in this search's material.
  skir.TypeUse? declaredType(skir.TypeTemplate template) =>
      catalog.declaredBindingType(template, subject);

  /// [value] bound as [declaration] declares it.
  PortableExpressionBinding declared(
    skir.BindingDeclaration declaration,
    skir.DataValue value,
  ) => PortableExpressionBinding(
    value: value,
    schema: switch (declaredType(declaration.type)) {
      final use? => CompletePortablePresentationBinding(use),
      null => null,
    },
  );

  /// The bindings search expressions see: the invocation context, the query,
  /// every selector value and, for row expressions, the [row].
  Map<skir.ExpressionBindingId, PortableExpressionBinding> expressionBindings({
    required SearchQueryContext query,
    required skir.BindingDeclaration queryBinding,
    required Iterable<skir.SearchSelectorDefinition> selectors,
    (skir.BindingDeclaration, skir.DataValue)? row,
  }) {
    final bindings = <skir.ExpressionBindingId, PortableExpressionBinding>{
      ...context.bindings,
      queryBinding.id: declared(
        queryBinding,
        skir.DataValue.wrapStringValue(query.normalizedQuery),
      ),
      if (row case (final declaration, final value))
        declaration.id: declared(declaration, value),
    };
    for (final definition in selectors) {
      final values = query.selectors
          .where((value) => value.selectorId == definition.selectorId)
          .map((value) => value.value)
          .whereType<String>()
          .toList(growable: false);
      bindings[definition.valueBinding.id] = declared(
        definition.valueBinding,
        definition.multiplicity == skir.SearchSelectorMultiplicity.multiple
            ? skir.DataValue.createListValue(
                items: [
                  for (final (index, value) in values.indexed)
                    skir.ListItem(
                      id: skir.ItemId(
                        value:
                            "search:${definition.selectorId}:selector:$index",
                      ),
                      value: skir.DataValue.wrapStringValue(value),
                    ),
                ],
              )
            : skir.DataValue.wrapStringValue(values.firstOrNull ?? ""),
      );
    }
    return Map.unmodifiable(bindings);
  }

  /// Evaluates [expression] over [bindings] in this search's material.
  PortableExpressionResult evaluateWith(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    skir.ExpressionNode expression,
  ) => PortableExpressionEvaluator.located(
    bindings,
    budget: budget,
    catalog: catalog,
    queries: context.queries,
    subject: subject,
  ).evaluate(expression);

  PortableExpressionResult evaluate(
    skir.ExpressionNode expression, {
    required SearchQueryContext query,
    required skir.BindingDeclaration queryBinding,
    required Iterable<skir.SearchSelectorDefinition> selectors,
    (skir.BindingDeclaration, skir.DataValue)? row,
  }) => evaluateWith(
    expressionBindings(
      query: query,
      queryBinding: queryBinding,
      selectors: selectors,
      row: row,
    ),
    expression,
  );

  PortableExpressionBinding? binding(skir.ExpressionBindingId id) =>
      context.bindings[id];
}
