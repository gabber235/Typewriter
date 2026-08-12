part of "editor_presentation_codec.dart";

extension SkirPresentationInteractionDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _button(wire.ButtonElement value) =>
      combineResults(
        expressions.decode(value.label),
        actions.decode(value.action),
        (label, action) => ButtonElement(label: label, action: action),
      );

  TypeResult<PresentationElement> _iconButton(wire.IconButtonElement value) {
    final icon = expressions.decode(value.icon);
    final label = expressions.decode(value.semanticLabel);
    final action = actions.decode(value.action);
    final diagnostics = [
      ...icon.diagnostics,
      ...label.diagnostics,
      ...action.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            IconButtonElement(
              icon: icon.valueOrNull!,
              semanticLabel: label.valueOrNull!,
              action: action.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _menu(wire.MenuElement value) {
    if (value.items.isEmpty) return invalidWire("Menu items are empty");
    final label = _optionalExpression(value.label);
    final items = <PresentationMenuItem>[];
    final diagnostics = <TypeDiagnostic>[...label.diagnostics];
    for (final item in value.items) {
      final itemLabel = expressions.decode(item.label);
      final action = actions.decode(item.action);
      diagnostics
        ..addAll(itemLabel.diagnostics)
        ..addAll(action.diagnostics);
      if (item.itemId.isEmpty) {
        diagnostics.add(wireDiagnostic("Menu item id is empty"));
      } else if (itemLabel.valueOrNull case final decodedLabel?) {
        if (action.valueOrNull case final decodedAction?) {
          items.add(
            PresentationMenuItem(
              id: item.itemId,
              label: decodedLabel,
              action: decodedAction,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            MenuElement(items: items, label: label.valueOrNull),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _tooltip(wire.TooltipElement value) =>
      expressions
          .decode(value.message)
          .mapValue(
            (message) => TooltipElement(
              message: message,
              child: decodeNode(value.child),
            ),
          );
}
