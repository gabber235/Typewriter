part of "../../data_renderer.dart";

extension RepeatedElementRendering on RepeatedElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _RepeatedRenderer(element: this, scope: scope);
}

class _RepeatedRenderer extends StatelessWidget {
  const _RepeatedRenderer({required this.element, required this.scope});

  final RepeatedElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final result = scope.evaluate(element.source);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final items = result.valueOrNull!._repeatedItems(element.source, scope);
    if (items == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Repeated source must evaluate to a list or map",
        ),
      ]);
    }
    if (items.isEmpty) {
      return renderSequence(
        context: context,
        presentation: element.presentation,
        scope: scope,
        itemScopes: const [],
      );
    }
    return renderSequence(
      context: context,
      presentation: element.presentation,
      scope: scope,
      itemScopes: [for (final item in items) _itemScope(item)],
    );
  }

  PresentationRenderScope _itemScope(_RepeatedItem item) {
    final expressions = scope.expressions.withBinding(
      element.itemBindingId,
      BindingSnapshot(
        type: item.type,
        value: item.value,
        revision: item.revision,
        writable: item.canonical != null,
      ),
    );
    if (item.canonical == null) return scope.copyWith(expressions: expressions);
    return scope.copyWith(
      expressions: expressions,
      aliases: {...scope.aliases, element.itemBindingId: item.canonical!},
    );
  }
}

extension on DataValue {
  List<_RepeatedItem>? _repeatedItems(
    TypedExpression source,
    PresentationRenderScope scope,
  ) {
    final sourceBinding = source.expression is BindingExpression
        ? (source.expression as BindingExpression).binding
        : null;
    final canonical = sourceBinding == null
        ? null
        : scope.canonical(sourceBinding);
    final revision = sourceBinding == null
        ? 0
        : scope.resolve(sourceBinding).valueOrNull?.revision ?? 0;
    return switch ((this, source.resultType)) {
      (ListValue(:final values), ListType(:final element)) => [
        for (final entry in values.indexed)
          _RepeatedItem(
            type: element,
            value: entry.$2,
            revision: revision,
            canonical: canonical?.at(DataPath.root.index(entry.$1)),
          ),
      ],
      (MapValue(:final entries), MapType(value: final valueType)) => [
        for (final entry in entries)
          _RepeatedItem(
            type: valueType,
            value: entry.value,
            revision: revision,
            canonical: canonical?.at(DataPath.root.mapKey(entry.key)),
          ),
      ],
      _ => null,
    };
  }
}

@freezed
abstract class _RepeatedItem with _$RepeatedItem {
  const factory _RepeatedItem({
    required TypeExpression type,
    required DataValue value,
    required int revision,
    required BindingReference? canonical,
  }) = _RepeatedItemValue;
}
