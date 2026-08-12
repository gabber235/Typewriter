import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension InteractionElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return switch (element) {
      ButtonElement() => FilledButton(
        onPressed: element.action._enabled(scope)
            ? () => scope.invoke(element.action)
            : null,
        child: Text(scope.expressionText(element.label)),
      ),
      IconButtonElement() => element._renderButton(context, scope),
      MenuElement() => element._menu(scope),
      TooltipElement() => Tooltip(
        message: scope.expressionText(element.message),
        child: PresentationNodeRenderer(node: element.child, scope: scope),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

extension on EditorAction {
  bool _enabled(PresentationRenderScope scope) =>
      scope.enabled && (this is RealmEditorAction || !scope.readOnly);
}

extension on IconButtonElement {
  Widget _renderButton(BuildContext context, PresentationRenderScope scope) {
    final result = scope.evaluate(icon);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final value = result.valueOrNull?.iconValueOrNull;
    if (value == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Button icon must evaluate to the nominal Icon type",
        ),
      ]);
    }
    return IconButton(
      tooltip: scope.expressionText(semanticLabel),
      onPressed: action._enabled(scope) ? () => scope.invoke(action) : null,
      icon: Icones.value(value),
    );
  }
}

extension on MenuElement {
  Widget _menu(PresentationRenderScope scope) {
    final label = this.label == null ? null : scope.expressionText(this.label!);
    return ContextMenuRegion(
      enableGestures: false,
      items: [
        for (final item in items)
          MenuItem(
            label: scope.expressionText(item.label),
            onPressed: item.action._enabled(scope)
                ? () => scope.invoke(item.action)
                : null,
          ),
      ],
      builder: (context, controller, child) => label == null
          ? IconButton(
              tooltip: "Open menu",
              onPressed: ContextMenuRegion.onPress(controller),
              icon: const Icones("mdi:dots-vertical"),
            )
          : TextButton(
              onPressed: ContextMenuRegion.onPress(controller),
              child: Text(label),
            ),
    );
  }
}
