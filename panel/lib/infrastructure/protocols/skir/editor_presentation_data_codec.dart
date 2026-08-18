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
    return combineResults(
      expressions.decode(value.source),
      _sequence(value.presentation),
      (source, presentation) => RepeatedElement(
        source: source,
        itemBindingId: BindingId(value.itemBindingId.value),
        presentation: presentation,
      ),
    );
  }

  TypeResult<SequencePresentation> _sequence(wire.SequencePresentation value) =>
      _sequenceLayout(value.layout).mapValue(
        (layout) => SequencePresentation(
          item: decodeNode(value.item),
          empty: value.empty == null ? null : decodeNode(value.empty!),
          separator: value.separator == null
              ? null
              : decodeNode(value.separator!),
          layout: layout,
        ),
      );

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

  TypeResult<PresentationElement> _polymorphicMatch(
    wire.PolymorphicMatchElement value,
  ) {
    final binding = expressions.binding(value.binding);
    final cases = <PolymorphicMatchCase>[];
    final diagnostics = <TypeDiagnostic>[...binding.diagnostics];
    for (final item in value.cases) {
      final type = types.decodeReference(item.concreteType);
      diagnostics.addAll(type.diagnostics);
      if (type.valueOrNull case final decodedType?) {
        cases.add(
          PolymorphicMatchCase(
            type: decodedType,
            child: decodeNode(item.child),
          ),
        );
      }
    }
    if (cases.isEmpty) {
      diagnostics.add(wireDiagnostic("Polymorphic match has no cases"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            PolymorphicMatchElement(
              binding: binding.valueOrNull!,
              scopeBindingId: BindingId(value.scopeBindingId.value),
              cases: cases,
              fallback: value.fallback == null
                  ? null
                  : decodeNode(value.fallback!),
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _collectionLookup(
    wire.CollectionLookupElement value,
  ) {
    if (value.sourceId.isEmpty) {
      return invalidWire("Collection source ID is empty");
    }
    return expressions
        .binding(value.key)
        .mapValue(
          (key) => CollectionLookupElement(
            sourceId: PresentationCollectionSourceId(value.sourceId),
            key: key,
            found: decodeNode(value.found),
            missing: decodeNode(value.missing),
            loading: value.loading == null ? null : decodeNode(value.loading!),
          ),
        );
  }

  TypeResult<PresentationElement> _collectionGraph(
    wire.CollectionGraphElement value,
  ) {
    if (value.sourceId.isEmpty || value.relationId.isEmpty) {
      return invalidWire("Collection graph identifiers must not be empty");
    }
    if (value.maximumDepth case final maximumDepth? when maximumDepth <= 0) {
      return invalidWire("Collection graph maximum depth must be positive");
    }
    final direction = switch (value.direction) {
      wire.CollectionGraphDirection.forward => CollectionGraphDirection.forward,
      wire.CollectionGraphDirection.reverse => CollectionGraphDirection.reverse,
      wire.CollectionGraphDirection_unknown() => null,
    };
    if (direction == null) {
      return invalidWire("Collection graph direction is unknown");
    }
    final roots = expressions.binding(value.roots);
    final rootSequence = _sequence(value.rootSequence);
    final node = decodeNode(value.node);
    final children = _sequence(value.children);
    final diagnostics = [
      ...roots.diagnostics,
      ...rootSequence.diagnostics,
      ...children.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            CollectionGraphElement(
              sourceId: PresentationCollectionSourceId(value.sourceId),
              roots: roots.valueOrNull!,
              rootSequence: rootSequence.valueOrNull!,
              relation: PresentationCollectionRelationId(value.relationId),
              direction: direction,
              node: node,
              childrenBindingId: BindingId(value.childrenBindingId.value),
              childBindingId: BindingId(value.childBindingId.value),
              children: children.valueOrNull!,
              maximumDepth: value.maximumDepth,
            ),
          )
        : TypeResult.failure(diagnostics);
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
