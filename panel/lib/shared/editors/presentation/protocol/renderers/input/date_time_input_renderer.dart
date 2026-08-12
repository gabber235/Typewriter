part of "../../simple_input_renderer.dart";

extension DateTimeInputElementRendering on DateTimeInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final child = _renderParsedTextValue(
      binding: binding,
      scope: scope,
      text: binding.value is TimestampValue
          ? (binding.value as TimestampValue).value.toIso8601String()
          : null,
      parse: (text) {
        final parsed = DateTime.tryParse(text);
        return parsed == null ? null : TimestampValue(parsed);
      },
      diagnostic: "Timestamp control requires an ISO 8601 timestamp binding",
    );
    return LabeledControl(control: control, scope: scope, child: child);
  }
}
