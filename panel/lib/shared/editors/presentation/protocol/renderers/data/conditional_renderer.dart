part of "../../data_renderer.dart";

extension ConditionalElementRendering on ConditionalElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.evaluate(condition);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final value = result.valueOrNull;
    if (value is! BooleanValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Conditional expression must evaluate to boolean",
        ),
      ]);
    }
    final selected = value.value ? whenTrue : whenFalse;
    return selected == null
        ? const SizedBox.shrink()
        : PresentationNodeRenderer(node: selected, scope: scope);
  }
}
