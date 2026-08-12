part of "editor_presentation_encoder.dart";

extension SkirPresentationDataEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _typedField(TypedFieldElement value) {
    final binding = expressions.binding(value.binding);
    final type = types.encodeExpression(value.expectedType);
    final presentation = value.presentation == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.presentation!).mapValue((value) => value);
    final diagnostics = [
      ...binding.diagnostics,
      ...type.diagnostics,
      ...presentation.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createTypedField(
              binding: binding.valueOrNull!,
              expectedType: type.valueOrNull!,
              presentation: presentation.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _conditional(ConditionalElement value) {
    final condition = expressions.encode(value.condition);
    final whenTrue = encodeNode(value.whenTrue);
    final whenFalse = value.whenFalse == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.whenFalse!).mapValue((value) => value);
    final diagnostics = [
      ...condition.diagnostics,
      ...whenTrue.diagnostics,
      ...whenFalse.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createConditional(
              condition: condition.valueOrNull!,
              whenTrue: whenTrue.valueOrNull!,
              whenFalse: whenFalse.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _repeated(RepeatedElement value) {
    final source = expressions.encode(value.source);
    final template = encodeNode(value.template);
    final empty = value.empty == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.empty!).mapValue((value) => value);
    final diagnostics = [
      ...source.diagnostics,
      ...template.diagnostics,
      ...empty.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createRepeated(
              source: source.valueOrNull!,
              itemBindingId: wire_binding.BindingId(
                value: value.itemBindingId.value,
              ),
              template: template.valueOrNull!,
              empty: empty.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _scoped(ScopedBindingElement value) {
    final binding = expressions.binding(value.binding);
    final child = encodeNode(value.child);
    return combineResults(
      binding,
      child,
      (binding, child) => wire.PresentationElement.createScopedBinding(
        binding: binding,
        scopeBindingId: wire_binding.BindingId(
          value: value.scopeBindingId.value,
        ),
        child: child,
      ),
    );
  }

  TypeResult<wire.PresentationElement> _defaultPresentation(
    DefaultPresentationElement value,
  ) => expressions
      .binding(value.binding)
      .mapValue(
        (binding) => wire.PresentationElement.createDefaultPresentation(
          binding: binding,
          presentationId: value.presentationId == null
              ? null
              : wire_type.PresentationId(
                  namespace: value.presentationId!.namespace,
                  name: value.presentationId!.name,
                ),
        ),
      );
}
