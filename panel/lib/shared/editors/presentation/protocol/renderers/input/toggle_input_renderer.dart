part of "../../simple_input_renderer.dart";

extension ToggleInputElementRendering on ToggleInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    if (binding.type is! BooleanType || binding.value is! BooleanValue) {
      return _inputDiagnostic("Toggle control requires a boolean binding");
    }
    return const SizedBox.shrink();
  }
}
