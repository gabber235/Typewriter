part of "../../simple_input_renderer.dart";

extension DateTimeInputElementRendering on DateTimeInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    if (!includeDate && !includeTime) {
      return _inputDiagnostic(
        "Date and time control must enable at least one part",
      );
    }
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    if (binding.type is! TimestampType || binding.value is! TimestampValue) {
      return _inputDiagnostic("Date and time control requires a timestamp");
    }
    final value = (binding.value as TimestampValue).value;
    final child = DateTimePickerField(
      value: value,
      includeDate: includeDate,
      includeTime: includeTime,
      enabled: scope.enabled && binding.writable,
      readOnly: scope.readOnly,
      onChanged: (next) {
        scope.update(binding.reference, TimestampValue(next));
      },
    );
    return LabeledControl(control: control, scope: scope, child: child);
  }
}
