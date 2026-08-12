part of "editor_presentation_codec.dart";

extension SkirPresentationDataDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _typedField(wire.TypedFieldElement value) {
    final binding = expressions.binding(value.binding);
    final type = types.decodeExpression(value.expectedType);
    return combineResults(binding, type, (binding, type) {
      return TypedFieldElement(
        binding: binding,
        expectedType: type,
        presentation: value.presentation == null
            ? null
            : decodeNode(value.presentation!),
      );
    });
  }

  TypeResult<PresentationElement> _conditional(wire.ConditionalElement value) =>
      expressions
          .decode(value.condition)
          .mapValue(
            (condition) => ConditionalElement(
              condition: condition,
              whenTrue: decodeNode(value.whenTrue),
              whenFalse: value.whenFalse == null
                  ? null
                  : decodeNode(value.whenFalse!),
            ),
          );

  TypeResult<PresentationElement> _repeated(wire.RepeatedElement value) {
    return expressions
        .decode(value.source)
        .mapValue(
          (source) => RepeatedElement(
            source: source,
            itemBindingId: BindingId(value.itemBindingId.value),
            template: decodeNode(value.template),
            empty: value.empty == null ? null : decodeNode(value.empty!),
          ),
        );
  }

  TypeResult<PresentationElement> _scoped(wire.ScopedBindingElement value) {
    return expressions
        .binding(value.binding)
        .mapValue(
          (binding) => ScopedBindingElement(
            binding: binding,
            scopeBindingId: BindingId(value.scopeBindingId.value),
            child: decodeNode(value.child),
          ),
        );
  }

  TypeResult<PresentationElement> _defaultPresentation(
    wire.DefaultPresentationElement value,
  ) {
    final binding = expressions.binding(value.binding);
    final presentationId = value.presentationId == null
        ? const TypeResult<PresentationId?>.success(null)
        : value.presentationId!._decodeDomain().mapValue((value) => value);
    return combineResults(
      binding,
      presentationId,
      (binding, id) =>
          DefaultPresentationElement(binding: binding, presentationId: id),
    );
  }
}

extension on wire_type.PresentationId {
  TypeResult<PresentationId> _decodeDomain() {
    return namespace.isNotEmpty && name.isNotEmpty
        ? TypeResult.success(PresentationId(namespace: namespace, name: name))
        : invalidWire("Presentation id is not qualified");
  }
}
