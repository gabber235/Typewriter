part of "../../interaction_renderer.dart";

extension IconButtonElementRendering on IconButtonElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
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
      onPressed: action.enabledIn(scope) ? () => scope.invoke(action) : null,
      icon: Icones.value(value),
    );
  }
}
