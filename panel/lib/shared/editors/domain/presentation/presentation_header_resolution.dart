import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension PresentationHeaderComposition on PresentationHeader {
  PresentationHeader mergeInner(PresentationHeader inner) {
    final outerIds = items.map((item) => item.id).toSet();
    final merged = [
      for (final item in inner.items)
        if (!outerIds.contains(item.id)) item,
      ...items,
    ];
    return PresentationHeader(
      binding: binding ?? inner.binding,
      title: title ?? inner.title,
      description: description ?? inner.description,
      initiallyExpanded: initiallyExpanded ?? inner.initiallyExpanded,
      items: merged,
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
      ToggleInputElement() => element._toggleHeader(context),
      ListInputElement() => element._listHeader(context, registry),
      MapInputElement() => element._mapHeader(context, registry),
      _ => null,
    };
  }
}

extension on ToggleInputElement {
  PresentationHeader? _toggleHeader(ExpressionContext context) {
    final resolved = context.bindings.resolve(control.binding).valueOrNull;
    if (resolved case ResolvedBinding(
      type: BooleanType(),
      value: BooleanValue(:final value),
      :final writable,
    )) {
      return PresentationHeader(
        binding: control.binding,
        title: control.label,
        description: control.description,
        items: [
          HeaderBooleanToggleItem(
            id: booleanToggleHeaderItemId,
            label: (value ? "Disable" : "Enable").asStringLiteral,
            checked: TypedExpression(
              resultType: const BooleanType(),
              expression: BindingExpression(control.binding),
            ),
            priority: _integer(0x7fffffffffffffff),
            enabledIf: TypedExpression(
              resultType: const BooleanType(),
              expression: LiteralExpression(BooleanValue(writable)),
            ),
            placement: HeaderActionPlacement.beforeTitle,
            action: LocalEditorAction(
              SetValueAction(
                target: control.binding,
                value: TypedExpression(
                  resultType: const BooleanType(),
                  expression: LiteralExpression(BooleanValue(!value)),
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
        items: [
          HeaderButtonItem(
            id: listAddHeaderItemId,
            icon: _icon(Fa6Solid.plus),
            label: "Add item".asStringLiteral,
            priority: _integer(100),
            action: LocalEditorAction(
              AppendListItemAction(
                target: control.binding,
                value: TypedExpression(
                  resultType: element,
                  expression: LiteralExpression(initial),
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
        items: [
          HeaderButtonItem(
            id: mapAddHeaderItemId,
            icon: _icon(Fa6Solid.plus),
            label: "Add entry".asStringLiteral,
            priority: _integer(100),
            action: LocalEditorAction(
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
  expression: LiteralExpression(IconValue.from(value).typedValue),
);
