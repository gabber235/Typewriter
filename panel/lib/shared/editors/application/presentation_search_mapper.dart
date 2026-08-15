import "package:typewriter_panel/typewriter_panel.dart";

final class PresentationSearchMapper {
  const PresentationSearchMapper({
    required this.mapping,
    required this.registry,
    required this.budget,
    required this.providerKey,
  });

  final SearchResultMapping mapping;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final String providerKey;

  TypeResult<SearchResult> map({
    required DataValue value,
    required TypeExpression type,
    required ExpressionContext expressions,
  }) {
    final candidate = expressions.withBinding(
      mapping.bindingId,
      BindingSnapshot(type: type, value: value, revision: 0, writable: false),
    );
    final key = mapping.key.evaluate(
      candidate,
      registry: registry,
      budget: budget,
    );
    if (key case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final selected = mapping.selectedValue.evaluate(
      candidate,
      registry: registry,
      budget: budget,
    );
    if (selected case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final id = key.valueOrNull!.expressionDisplayText;
    if (id.isEmpty) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Search result keys must not be empty",
        ),
      ]);
    }
    return TypeResult.success(
      SearchResult(
        id: id,
        type: presentationSearchResultType,
        payload: PresentationSearchResultPayload(
          selectedValue: selected.valueOrNull!,
          presentation: mapping.presentation,
          expressions: candidate,
          providerKey: providerKey,
        ),
        title: id,
      ),
    );
  }
}
