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

  PortableExpressionResult evaluate(
    skir.ExpressionNode expression, {
    required SearchQueryContext query,
    required skir.ExpressionBindingId queryBindingId,
    required Iterable<skir.SearchSelectorDefinition> selectors,
    skir.ExpressionBindingId? rowBinding,
    skir.DataValue? rowValue,
  }) {
    final bindings = <skir.ExpressionBindingId, PortableExpressionBinding>{
      ...context.bindings,
      queryBindingId: PortableExpressionBinding(
        value: skir.DataValue.wrapStringValue(query.normalizedQuery),
      ),
      if (rowBinding != null && rowValue != null)
        rowBinding: PortableExpressionBinding(value: rowValue),
    };
    for (final definition in selectors) {
      final values = query.selectors
          .where((value) => value.selectorId == definition.selectorId)
          .map((value) => value.value)
          .whereType<String>()
          .toList(growable: false);
      bindings[definition.valueBindingId] = PortableExpressionBinding(
        value:
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
    return PortableExpressionEvaluator.located(
      bindings,
      budget: budget,
    ).evaluate(expression);
  }

  PortableExpressionBinding? binding(skir.ExpressionBindingId id) =>
      context.bindings[id];
}
