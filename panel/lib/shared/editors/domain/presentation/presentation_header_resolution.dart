import "package:typewriter_panel/typewriter_panel.dart";

extension PresentationHeaderComposition on PresentationHeader {
  PresentationHeader mergeInner(PresentationHeader inner) {
    final outerIds = actions.map((action) => action.id).toSet();
    final merged = [
      for (final action in inner.actions)
        if (!outerIds.contains(action.id)) action,
      ...actions,
    ];
    return PresentationHeader(
      binding: binding ?? inner.binding,
      title: title ?? inner.title,
      description: description ?? inner.description,
      initiallyExpanded: initiallyExpanded ?? inner.initiallyExpanded,
      actions: merged,
    );
  }
}

extension PresentationElementHeaderContribution on PresentationElement {
  PresentationHeader? contributeHeader(
    ExpressionContext context, {
    required TypeRegistry registry,
  }) {
    final element = this;
    return switch (element) {
      ListInputElement() => element._listHeader(context, registry),
      MapInputElement() => element._mapHeader(context, registry),
      _ => null,
    };
  }
}

extension on ListInputElement {
  PresentationHeader? _listHeader(
    ExpressionContext context,
    TypeRegistry registry,
  ) {
    if (!allowAdd) return null;
    final resolved = context.bindings.resolve(control.binding).valueOrNull;
    if (resolved?.type case ListType(:final element)) {
      final initial = element
          .createInitialValue(registry: registry)
          .valueOrNull;
      if (initial == null) return null;
      return PresentationHeader(
        binding: control.binding,
        title: control.label,
        description: control.description,
        initiallyExpanded: control.binding.path.segments.isEmpty,
        actions: [
          EditorHeaderAction(
            id: listAddHeaderActionId,
            icon: _icon("mdi:plus"),
            label: "Add item".asStringLiteral,
            priority: _integer(100),
            activation: InvokeHeaderAction(
              LocalEditorAction(
                AppendListItemAction(
                  target: control.binding,
                  value: TypedExpression(
                    resultType: element,
                    expression: LiteralExpression(initial),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return null;
  }
}

extension on MapInputElement {
  PresentationHeader? _mapHeader(
    ExpressionContext context,
    TypeRegistry registry,
  ) {
    if (!allowAdd) return null;
    final resolved = context.bindings.resolve(control.binding).valueOrNull;
    if (resolved?.type case MapType(:final key, :final value)) {
      final initialKey = key.createInitialValue(registry: registry).valueOrNull;
      final initialValue = value
          .createInitialValue(registry: registry)
          .valueOrNull;
      if (initialKey == null || initialValue == null) return null;
      return PresentationHeader(
        binding: control.binding,
        title: control.label,
        description: control.description,
        initiallyExpanded: control.binding.path.segments.isEmpty,
        actions: [
          EditorHeaderAction(
            id: mapAddHeaderActionId,
            icon: _icon("mdi:plus"),
            label: "Add entry".asStringLiteral,
            priority: _integer(100),
            activation: InvokeHeaderAction(
              LocalEditorAction(
                PutMapEntryAction(
                  target: control.binding,
                  key: TypedExpression(
                    resultType: key,
                    expression: LiteralExpression(initialKey),
                  ),
                  value: TypedExpression(
                    resultType: value,
                    expression: LiteralExpression(initialValue),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return null;
  }
}

TypedExpression _integer(int value) => TypedExpression(
  resultType: const IntegerType(width: IntegerWidth.signed64),
  expression: LiteralExpression(IntegerValue(BigInt.from(value))),
);

TypedExpression _icon(String value) => TypedExpression(
  resultType: NamedType(standardTypeRefs.icon),
  expression: LiteralExpression(IconValue.iconify(value).typedValue),
);
