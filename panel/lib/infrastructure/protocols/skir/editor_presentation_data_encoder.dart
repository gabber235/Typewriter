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
    final presentation = _sequence(value.presentation);
    final diagnostics = [...source.diagnostics, ...presentation.diagnostics];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createRepeated(
              source: source.valueOrNull!,
              itemBindingId: wire_binding.BindingId(
                value: value.itemBindingId.value,
              ),
              presentation: presentation.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.SequencePresentation> _sequence(SequencePresentation value) {
    final item = encodeNode(value.item);
    final empty = value.empty == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.empty!).mapValue((value) => value);
    final separator = value.separator == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.separator!).mapValue((value) => value);
    final layout = _sequenceLayout(value.layout);
    final diagnostics = [
      ...item.diagnostics,
      ...empty.diagnostics,
      ...separator.diagnostics,
      ...layout.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.SequencePresentation(
              item: item.valueOrNull!,
              empty: empty.valueOrNull,
              separator: separator.valueOrNull,
              layout: layout.valueOrNull!,
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

  TypeResult<wire.PresentationElement> _polymorphicMatch(
    PolymorphicMatchElement value,
  ) {
    final binding = expressions.binding(value.binding);
    final fallback = value.fallback == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.fallback!).mapValue((value) => value);
    final cases = <wire.PolymorphicMatchCase>[];
    final diagnostics = <TypeDiagnostic>[
      ...binding.diagnostics,
      ...fallback.diagnostics,
    ];
    for (final item in value.cases) {
      final type = types.encodeReference(item.type);
      final child = encodeNode(item.child);
      diagnostics
        ..addAll(type.diagnostics)
        ..addAll(child.diagnostics);
      if (type.valueOrNull case final encodedType?) {
        if (child.valueOrNull case final encodedChild?) {
          cases.add(
            wire.PolymorphicMatchCase(
              concreteType: encodedType,
              child: encodedChild,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createPolymorphicMatch(
              binding: binding.valueOrNull!,
              scopeBindingId: wire_binding.BindingId(
                value: value.scopeBindingId.value,
              ),
              cases: cases,
              fallback: fallback.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _collectionLookup(
    CollectionLookupElement value,
  ) {
    final key = expressions.binding(value.key);
    final found = encodeNode(value.found);
    final missing = encodeNode(value.missing);
    final loading = value.loading == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.loading!).mapValue((value) => value);
    final diagnostics = [
      ...key.diagnostics,
      ...found.diagnostics,
      ...missing.diagnostics,
      ...loading.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createCollectionLookup(
              sourceId: value.sourceId.value,
              key: key.valueOrNull!,
              found: found.valueOrNull!,
              missing: missing.valueOrNull!,
              loading: loading.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _collectionGraph(
    CollectionGraphElement value,
  ) {
    final roots = expressions.binding(value.roots);
    final rootSequence = _sequence(value.rootSequence);
    final node = encodeNode(value.node);
    final children = _sequence(value.children);
    final diagnostics = [
      ...roots.diagnostics,
      ...rootSequence.diagnostics,
      ...node.diagnostics,
      ...children.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createCollectionGraph(
              sourceId: value.sourceId.value,
              roots: roots.valueOrNull!,
              rootSequence: rootSequence.valueOrNull!,
              relationId: value.relation.value,
              direction: switch (value.direction) {
                CollectionGraphDirection.forward =>
                  wire.CollectionGraphDirection.forward,
                CollectionGraphDirection.reverse =>
                  wire.CollectionGraphDirection.reverse,
              },
              node: node.valueOrNull!,
              childrenBindingId: wire_binding.BindingId(
                value: value.childrenBindingId.value,
              ),
              childBindingId: wire_binding.BindingId(
                value: value.childBindingId.value,
              ),
              children: children.valueOrNull!,
              maximumDepth: value.maximumDepth,
            ),
          )
        : TypeResult.failure(diagnostics);
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
