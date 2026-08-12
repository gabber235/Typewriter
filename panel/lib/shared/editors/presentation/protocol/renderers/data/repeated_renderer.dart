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
      return element.empty == null
          ? const SizedBox.shrink()
          : PresentationNodeRenderer(node: element.empty!, scope: scope);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _item(item),
          ),
      ],
    );
  }

  Widget _item(_RepeatedItem item) {
    final childScope = _itemScope(item);
    final localizedTemplate = element.template.localizeFailures(
      childScope.expressions,
      registry: childScope.registry,
      budget: childScope.budget,
    );
    return PresentationNodeRenderer(node: localizedTemplate, scope: childScope);
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
