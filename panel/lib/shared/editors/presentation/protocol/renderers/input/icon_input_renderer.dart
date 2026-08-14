part of "../../simple_input_renderer.dart";

extension IconInputElementRendering on IconInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final value = switch (binding.value) {
      StringValue(:final value) => value,
      _ => null,
    };
    if (value == null) {
      return _inputDiagnostic("Icon control requires a string value");
    }
    return LabeledControl(
      control: control,
      scope: scope,
      child: IconSelector(
        value: value,
        enabled: scope.enabled && binding.writable,
        readOnly: scope.readOnly,
        onChanged: (next) {
          final value = StringValue(next);
          if (value.validateAgainst(binding.type).isEmpty) {
            scope.update(binding.reference, value);
          }
        },
      ),
    );
  }
}
