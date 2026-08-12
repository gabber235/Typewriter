part of "editor_presentation_encoder.dart";

extension SkirPresentationInteractionEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _button(ButtonElement value) =>
      combineResults(
        expressions.encode(value.label),
        actions.encode(value.action),
        (label, action) =>
            wire.PresentationElement.createButton(label: label, action: action),
      );

  TypeResult<wire.PresentationElement> _iconButton(IconButtonElement value) {
    final icon = expressions.encode(value.icon);
    final label = expressions.encode(value.semanticLabel);
    final action = actions.encode(value.action);
    final diagnostics = [
      ...icon.diagnostics,
      ...label.diagnostics,
      ...action.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createIconButton(
              icon: icon.valueOrNull!,
              semanticLabel: label.valueOrNull!,
              action: action.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _menu(MenuElement value) {
    final label = _optional(value.label);
    final items = <wire.MenuItem>[];
    final diagnostics = <TypeDiagnostic>[...label.diagnostics];
    for (final item in value.items) {
      final itemLabel = expressions.encode(item.label);
      final action = actions.encode(item.action);
      diagnostics
        ..addAll(itemLabel.diagnostics)
        ..addAll(action.diagnostics);
      if (itemLabel.valueOrNull case final encodedLabel?) {
        if (action.valueOrNull case final encodedAction?) {
          items.add(
            wire.MenuItem(
              itemId: item.id,
              label: encodedLabel,
              action: encodedAction,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createMenu(
              label: label.valueOrNull,
              items: items,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _tooltip(TooltipElement value) =>
      combineResults(
        expressions.encode(value.message),
        encodeNode(value.child),
        (message, child) => wire.PresentationElement.createTooltip(
          message: message,
          child: child,
        ),
      );
}
