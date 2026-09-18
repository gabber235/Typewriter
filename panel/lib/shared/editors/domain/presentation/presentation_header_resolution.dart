import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Combines generated collection controls with a declared header.
///
/// The receiver is the outer header and wins for fields it supplies. Its item
/// IDs also shadow inner items, which lets an explicit declaration replace a
/// standard action without changing the renderer that consumes the result.
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
      headerPadding: headerPadding ?? inner.headerPadding,
      contentPadding: contentPadding ?? inner.contentPadding,
    );
  }
}

/// Derives standard header actions from input element state.
///
/// List and map controls contribute add actions only when insertion is enabled
/// and an initial value can be constructed. A toggle contributes a state aware
/// action only when its binding resolves to a boolean. Missing or non ready
/// bindings return no contribution, leaving the declared presentation intact.
extension PresentationElementHeaderContribution on PresentationElement {
  PresentationHeader? contributeHeader(PresentationRenderScope scope) {
    final element = this;
    return switch (element) {
      ToggleInputElement() => element._toggleHeader(scope),
      ListInputElement() => element._listHeader(scope),
      MapInputElement() => element._mapHeader(scope),
      _ => null,
    };
  }
}

extension on ToggleInputElement {
  PresentationHeader? _toggleHeader(PresentationRenderScope scope) {
    final resolved = scope.resolve(control.binding).valueOrNull;
    if (resolved case ResolvedBinding(
      value: BooleanValue(:final value),
      :final writable,
    )) {
      return PresentationHeader(
        binding: control.binding,
        title: control.label?.asHeaderTitle,
        description: control.description,
        items: [
          HeaderBooleanToggleItem(
            id: booleanToggleHeaderItemId,
            label: (value ? "Disable" : "Enable").asStringLiteral,
            checked: TypedExpression(
              resultType: const BooleanType(),
              expression: BindingExpression(control.binding),
            ),
            priority: IntegerValue(BigInt.parse("9223372036854775807"))
                .asLiteral(const IntegerType(width: IntegerWidth.signed64)),
            enabledIf: writable.asBooleanLiteral,
            placement: HeaderActionPlacement.beforeTitle,
            action: LocalEditorAction(
              SetValueAction(
                target: control.binding,
                value: (!value).asBooleanLiteral,
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
  PresentationHeader? _listHeader(PresentationRenderScope scope) {
    if (!allowAdd) return null;
    final inspected = scope.inspect(control.binding).valueOrNull;
    if (inspected?.type.bindingRepresentation(scope.registry) case ListType(
      :final element,
    )) {
      final reference = scope.canonical(control.binding);
      final structural = scope.editOwnerFor?.call(reference);
      final initial = element
          .createInitialValue(registry: scope.registry)
          .valueOrNull;
      if (initial == null && structural is! EditorStructureOwner) return null;
      return PresentationHeader(
        binding: control.binding,
        title: control.label?.asHeaderTitle,
        description: control.description,
        initiallyExpanded: control.binding.path.segments.isEmpty,
        items: [
          HeaderButtonItem(
            id: listAddHeaderItemId,
            icon: Fa6Solid.plus.asIconLiteral,
            label: "Add item".asStringLiteral,
            priority: 100.asSigned64Literal,
            action: LocalEditorAction(
              AppendListItemAction(
                target: control.binding,
                value: TypedExpression(
                  resultType: element,
                  expression: LiteralExpression(initial ?? const UnitValue()),
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
  PresentationHeader? _mapHeader(PresentationRenderScope scope) {
    if (!allowAdd) return null;
    final inspected = scope.inspect(control.binding).valueOrNull;
    if (inspected?.type.bindingRepresentation(scope.registry) case MapType(
      :final key,
      :final value,
    )) {
      final reference = scope.canonical(control.binding);
      final structural = scope.editOwnerFor?.call(reference);
      final initialKey = key
          .createInitialValue(registry: scope.registry)
          .valueOrNull;
      final initialValue = value
          .createInitialValue(registry: scope.registry)
          .valueOrNull;
      if ((initialKey == null || initialValue == null) &&
          structural is! EditorStructureOwner) {
        return null;
      }
      return PresentationHeader(
        binding: control.binding,
        title: control.label?.asHeaderTitle,
        description: control.description,
        initiallyExpanded: control.binding.path.segments.isEmpty,
        items: [
          HeaderButtonItem(
            id: mapAddHeaderItemId,
            icon: Fa6Solid.plus.asIconLiteral,
            label: "Add entry".asStringLiteral,
            priority: 100.asSigned64Literal,
            action: LocalEditorAction(
              PutMapEntryAction(
                target: control.binding,
                key: TypedExpression(
                  resultType: key,
                  expression: LiteralExpression(
                    initialKey ?? const UnitValue(),
                  ),
                ),
                value: TypedExpression(
                  resultType: value,
                  expression: LiteralExpression(
                    initialValue ?? const UnitValue(),
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
