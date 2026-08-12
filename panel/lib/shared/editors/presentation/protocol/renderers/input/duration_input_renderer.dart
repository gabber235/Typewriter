part of "../../simple_input_renderer.dart";

extension DurationInputElementRendering on DurationInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final child = _renderParsedTextValue(
      binding: binding,
      scope: scope,
      text: binding.value is DurationValue
          ? (binding.value as DurationValue).value.inMilliseconds.toString()
          : null,
      parse: (text) {
        final milliseconds = int.tryParse(text);
        return milliseconds == null
            ? null
            : DurationValue(Duration(milliseconds: milliseconds));
      },
      diagnostic: "Duration control requires milliseconds",
    );
    return LabeledControl(control: control, scope: scope, child: child);
  }
}
